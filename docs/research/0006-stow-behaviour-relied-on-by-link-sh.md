# GNU Stow behaviour that link.sh relies on

Research snapshot: 2026-09-03. GNU Stow 2.4.1 via Homebrew on macOS 26, and
Stow 2.3.1 from `apt` on the `ubuntu-24.04` GitHub Actions runner.

## Executive conclusion

Three Stow behaviours carry the guarantees this repository documents, and all
three were confirmed empirically. A conflicting target makes Stow exit non-zero
and apply nothing at all, `--no-folding` keeps shared directories real, and
`--delete` removes every link it created. `link_test.sh` pins each of them.

## A conflict is refused, and the whole invocation is abandoned

`README.md` states that existing files are treated as conflicts and never
overwritten or adopted, and ADR 0003 relies on the bootstrap failing rather
than clobbering a target. Both `check` and `install` exit 1 when a target
exists as a regular file, and the file is left byte-identical:

```console
$ printf '[user]\n\temail = someone@else\n' > "$SCRATCH/.gitconfig"
$ HOME="$SCRATCH" ./link.sh check > /dev/null 2>&1; echo $?
1
$ HOME="$SCRATCH" ./link.sh install > /dev/null 2>&1; echo $?
1
$ cat "$SCRATCH/.gitconfig"
[user]
	email = someone@else
```

The stronger and less obvious property is that the failure is not partial.
`link.sh` passes all three packages to a single `stow` invocation, and a
conflict in one of them leaves the other two unlinked as well:

```console
$ find "$SCRATCH" | sed "s|$SCRATCH|~|"
~
~/.gitconfig
$ find "$SCRATCH" -type l | wc -l
0
```

So a failed `install` needs no cleanup step: the target directory is left as it
was, apart from whatever caused the conflict. This is worth pinning, because a
future change that stowed each package in its own invocation would silently
turn a refused run into a half-applied one.

## `--no-folding` is what keeps shared directories usable

Without `--no-folding`, Stow links a whole directory when the target does not
exist yet, which would turn `~/.claude` and `~/.config/zsh/conf.d` into
symlinks into the repository. Application state written there would then land
inside the checkout. With the flag, those paths stay real directories holding
individual links, which is the property ADR 0001 describes.

Removing the flag is caught by `link_test.sh` rather than discovered later:
the shared directories become symlinks and the assertion fails.

## `readlink -f` is not portable

The test resolves symlinks to confirm they point into the repository. BSD
`readlink` on macOS has no `-f`, so the test uses bare `readlink` for the link
value and resolves it relative to the link's own directory with `cd -P`. This
keeps one test script working both locally and on the Linux runner.

## The test was mutation-checked

A test that passes proves nothing until it has been shown to fail. Each
assertion was verified by breaking `link.sh` in a way that assertion should
catch, running the test, and restoring the script:

| Mutation to `link.sh`                        | Result       |
| -------------------------------------------- | ------------ |
| Drop `git` from `PACKAGES`                   | caught       |
| Remove `--no-folding`                        | caught       |
| Replace `run_stow --delete` with `true`      | caught       |
| Add `--adopt` to `install`                   | caught       |
| Accept any subcommand instead of exiting `2` | caught       |

The `--adopt` mutation is the one worth keeping in mind. Stow's `--adopt` moves
an existing target file into the package and links it back, so an `install`
would appear to succeed while quietly rewriting a repository file from whatever
happened to be in `$HOME`. The conflict assertion fails in that case because
the run exits 0.

That mutation demonstrated the hazard on this repository while it was being
verified: `--adopt` replaced the contents of `git/.gitconfig` with the scratch
file's contents before the assertion ran, and the change had to be reverted
with `git checkout`. Anyone reproducing it should expect a dirty working tree,
and it is the reason `link.sh` must never grow an `--adopt` flag. `link_test.sh`
itself never passes `--adopt` and is safe to run repeatedly.

## Scope

`link_test.sh` covers `install`, `uninstall`, `check`, conflict refusal, and
usage. It does not cover `restow`, which is `--restow` over the same package
list and shares the code path.
