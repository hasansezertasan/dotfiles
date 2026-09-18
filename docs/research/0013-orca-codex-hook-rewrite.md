# How Orca rewrites the Codex hook definition

Research snapshot: 2026-09-18 on macOS 26.6. Orca installed from Homebrew Cask
at `/Applications/Orca.app`, with `/opt/homebrew/bin/orca` linking into its
bundle.

## Executive conclusion

`~/.codex/hooks.json` can hold a home-relative hook path — the definition this
repository used to commit did, and it ran — but Orca will not write one or keep
one. Its managed hook runtime builds the path with `os.homedir()` at write time
and single-quotes it into the generated command, so every definition Orca emits
is machine-specific. A reconciliation routine then rewrites the file whenever
its contents differ from the definition it expects, which is why restoring the
hand-written form does not hold. The limitation is the generator and its
reconciliation, not the hook format, and no setting changes either.

## What was observed first

`codex/.codex/hooks.json` in this repository appeared modified with no
deliberate edit. All eight hook entries had changed from

```sh
hook="$HOME/.orca/agent-hooks/codex-hook.sh"; if [ -f "$hook" ] && ...
```

to

```sh
if [ -f '/Users/hasansezertasan/.orca/agent-hooks/codex-hook.sh' ] && ...
```

The file was restored from Git at 23:17. By 23:18 it carried the expanded path
again, and `codex/.codex/hooks.json.bak` had been written beside it with the
same timestamp. The rewrite is therefore automatic and prompt, not a one-time
event from an earlier session.

## Locating the writer

`~/.orca/agent-hooks/` holds only the hook scripts that get invoked
(`codex-hook.sh`, `claude-hook.sh`, and siblings); none of them writes
`hooks.json`. Searching the application bundle found the writer:

```
/Applications/Orca.app/Contents/Resources/app.asar
/Applications/Orca.app/Contents/Resources/app.asar.unpacked/out/main/chunks/managed-home-shell-preflight-*.js
/Applications/Orca.app/Contents/Resources/relay/<platform>/managed-hook-runtime.js
```

`managed-hook-runtime.js` is shipped per platform and is minified but readable.

## Why Orca never emits `$HOME`

Two functions in that bundle settle it. The path is resolved in Node:

```js
function j(e) { return (0, Ht.join)((0, Cm.homedir)(), ".orca", "agent-hooks", e) }
```

and the generated shell command single-quotes whatever it is given:

```js
function Em(e) { return `'${e.replaceAll("'", "'\\''")}'` }
function I(e, t = {}, n = {}) {
  let o = Em(e), ...
  return `if ${[..., `[ -f ${o} ]`, `[ -r ${o} ]`, `[ -x ${o} ]`].join(" && ")}; then ${s}; else ${i}; fi`
}
```

`os.homedir()` expands the path before it is ever written, and `Em` single-quotes
the result, so nothing Orca generates can carry a shell variable. The bundle
contains six `$HOME` literals in total; all six belong to an unrelated snippet
that discovers the agent hook endpoint under `~/Library/Application Support`,
not to hook path construction.

This constrains Orca's output, not the file format. The definition this
repository committed took a different shape —

```sh
hook="$HOME/.orca/agent-hooks/codex-hook.sh"; if [ -f "$hook" ] && ...
```

— where the assignment is double-quoted, so `/bin/sh` expands `$HOME` normally.
That form is valid and worked for as long as it survived. What it cannot do is
survive Orca.

## Why a restore does not hold

The same bundle carries a reconciliation routine that logs under
`[codex-hook-promotion]`. It hashes the hook definition it finds against the one
it expects and writes the file when they differ, alongside the `config.toml`
trust entries that record hook approval. A file restored to the `$HOME` form
differs from the expected definition, so the next run rewrites it.

## Consequence for this repository

Managing the file through Stow puts the rewrite inside the working tree, since
the managed path is a symlink into the repository. The `$HOME` form is valid
shell and would keep working if it stayed, so the problem is purely that it
does not stay: keeping it would mean restoring the file after every rewrite, or
patching the vendored application bundle and re-patching it after each Orca
update. See
[ADR 0017](../adr/0017-stop-managing-the-codex-hook-definition.md) for the
decision taken.
