# How Orca rewrites the Codex hook definition

Research snapshot: 2026-09-18 on macOS 26.6. Orca installed from Homebrew Cask
at `/Applications/Orca.app`, with `/opt/homebrew/bin/orca` linking into its
bundle.

## Executive conclusion

`~/.codex/hooks.json` cannot hold a home-relative hook path. Orca's managed hook
runtime builds the path with `os.homedir()` at write time and wraps it in single
quotes, which suppress shell expansion, so a `$HOME` written by hand is neither
preserved nor usable. A reconciliation routine rewrites the file whenever its
contents differ from the definition Orca expects, which is why restoring the
file does not hold. No setting changes this; the path is hardcoded by
construction.

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

## Why `$HOME` cannot survive

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

`os.homedir()` expands the path before it is ever written, and single quotes
mean that a literal `$HOME` placed in the file by hand would be passed to
`/bin/sh` as four characters rather than expanded. The bundle contains six
`$HOME` literals in total; all six belong to an unrelated snippet that
discovers the agent hook endpoint under `~/Library/Application Support`, not to
hook path construction.

## Why a restore does not hold

The same bundle carries a reconciliation routine that logs under
`[codex-hook-promotion]`. It hashes the hook definition it finds against the one
it expects and writes the file when they differ, alongside the `config.toml`
trust entries that record hook approval. A file restored to the `$HOME` form
differs from the expected definition, so the next run rewrites it.

## Consequence for this repository

Managing the file through Stow puts the rewrite inside the working tree, since
the managed path is a symlink into the repository. The only ways to keep the
`$HOME` form would be to restore it manually after every rewrite, or to patch
the vendored application bundle and re-patch it after each Orca update. See
[ADR 0017](../adr/0017-stop-managing-the-codex-hook-definition.md) for the
decision taken.
