# Homebrew tap trust and non-interactive brew bundle runs

Research snapshot: 2026-09-03. Homebrew on `/opt/homebrew`, `arm64_tahoe`.

## Executive conclusion

Homebrew refuses to load a formula from a third-party tap until that tap or
formula is trusted, and `brew bundle install` cannot prompt for the decision.
The `Brewfile` declared six formulae from `hasansezertasan/tap` with a bare
`tap` line, so `brew bundle install` failed, and because `bootstrap.sh` guards
that command with `|| exit 1`, the whole bootstrap aborted. Declaring the trust
in the `tap` line fixes it.

## How it presented

`brew bundle check --no-upgrade` reported four formulae as missing even though
the tap was tapped and the formulae existed:

```console
$ brew bundle check --file Brewfile --no-upgrade --verbose
→ Formula hasansezertasan/tap/hwid needs to be installed.
→ Formula hasansezertasan/tap/nur needs to be installed.
→ Formula hasansezertasan/tap/ocom needs to be installed.
→ Formula hasansezertasan/tap/peta needs to be installed.
```

Attempting the install gives the actual reason:

```text
Error: Refusing to load formula hasansezertasan/tap/hwid from untrusted tap
hasansezertasan/tap.
Run `brew trust --formula hasansezertasan/tap/hwid` or
`brew trust hasansezertasan/tap` to trust it.
```

Trust is machine-local state, not tap content. `brew bundle dump` records it
alongside the tap, which is how the gap became visible -- the dump emitted more
than the `Brewfile` declared:

```console
$ brew bundle dump --taps --file=-
tap "hasansezertasan/tap", trusted: { formulae: ["cobo", "olink"] }
```

Only `cobo` and `olink` had been trusted, at some earlier point and by hand.
The other four had never been.

## Why this broke the bootstrap rather than one package

`bootstrap.sh` treats dependency installation as fatal:

```sh
brew bundle install --file "${DOTFILES_DIR}/Brewfile" --no-upgrade || exit 1
```

So an untrusted formula does not degrade to a missing tool; it ends the run
before the Stow links and the macOS settings are applied. On this machine the
failure was partial in the worst way: `shellcheck` is declared before the tap
block and installed successfully, so the run left new software behind and then
aborted. This is the consequence ADR 0003 recorded as "a later failure can
leave earlier changes applied", observed for real.

A fresh machine is affected worse. Trust is local, so a new checkout has no
trust for the tap at all and the run fails on the first formula, `cobo`, rather
than the fourth.

## The fix

`brew bundle` accepts the trust declaration inline, using the same syntax the
dump emits:

```text
tap "hasansezertasan/tap", trusted: { formulae: ["cobo", "hwid", "nur", "ocom", "olink", "peta"] }
```

This keeps the run non-interactive without a separate `brew trust` step in
`bootstrap.sh`, and it makes the trusted set explicit and reviewable rather
than depending on what each machine happened to accept by hand. The tap is the
repository owner's own, which is what makes declaring blanket trust for it
reasonable.

## Limitation: nothing in CI catches this class of bug

The failure depends on Homebrew, a tapped third-party tap, and machine-local
trust state, none of which exist on the Linux runners. `brew bundle` is not
exercised in CI at all, so this was only found by running the command. The
honest guard is to run `brew bundle install` on the repository owner's machine
after changing the `Brewfile`, and ultimately a real fresh-machine bootstrap,
which has still never been done.

## Unrelated finding: stale mise shims shadow Homebrew binaries

While confirming the `shellcheck` install, `command -v shellcheck` resolved to
`~/.local/share/mise/shims/shellcheck`, not Homebrew's copy, and that shim
errors because no mise version is set for it. The Zsh configuration places the
mise shim directory ahead of `/opt/homebrew/bin`:

```console
$ echo "$PATH" | tr ':' '\n' | grep -nE 'mise|homebrew'
2:/Users/hasansezertasan/.local/share/mise/shims
15:/opt/homebrew/bin
```

Five shims are both dangling and shadowing a Homebrew binary: `shellcheck`,
`cobo`, `idle3`, `idle3.14`, `python3-config`, and `python3.14-config`. The
`cobo` case is notable because `cobo` is not a mise tool at all, so the shim is
an orphaned file rather than a version-resolution problem, and `mise prune`
does not remove it -- `prune` only uninstalls older versions of tools still
required by some configuration.

This is machine state rather than repository content, so it is recorded here
rather than fixed by this change. It does mean the local ShellCheck command the
README documents does not currently work on this machine even with the formula
installed.
