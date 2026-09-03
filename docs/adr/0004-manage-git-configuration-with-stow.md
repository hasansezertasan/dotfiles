# Manage Git Configuration with Stow

## Context and Problem Statement

`~/.gitconfig` was the last hand-maintained configuration file outside the
repository, so its contents were unversioned and absent from a fresh machine.
It holds the commit identity, which is the kind of value that could differ per
machine, and Git writes to the file itself through `git config --global`.
Several other candidates share that last property: `~/.config/gh`,
`~/.config/zed`, `~/.config/atuin`, and `~/.config/mise` are all written by
their own applications.

## Considered Options

* Add a `git` package that tracks `~/.gitconfig`, identity included
* Track a shared `~/.gitconfig` and move identity into an untracked
  `~/.gitconfig.local` include
* Leave `~/.gitconfig` unmanaged
* Add `git` together with the `gh`, `zed`, `atuin`, and `mise` candidates

## Decision Outcome

Chosen option: "Add a `git` package that tracks `~/.gitconfig`, identity
included", because the current file contains nothing but this machine's
identity, so a split would leave an empty tracked file and an untracked one
holding everything that matters. The identity is already public in this
repository's commit history, and the global value was already the personal one,
so tracking it changes no behaviour.

Git resolves symlinks before taking its config lock, which was verified for
this decision: `git config --global` rewrites the tracked file in place and
leaves the link intact. Managed Git configuration therefore stays editable with
Git's own commands, and those edits surface as repository changes.

The other application-written candidates are deliberately left out. They need
checking individually first, both for credentials — `gh/hosts.yml` holds an
authentication token — and for whether each application preserves a symlink
when it rewrites its own config.

### Consequences

* Good, because the commit identity is versioned and applied by
  `./link.sh install` on a new machine.
* Good, because `git config --global` remains the normal way to change it and
  produces a reviewable diff.
* Good, because deferring the application-written candidates keeps credentials
  and unverified rewrite behaviour out of the repository.
* Bad, because a machine that needs a different identity has to add a
  `~/.gitconfig.local` include or stop managing the package.
* Bad, because an existing `~/.gitconfig` must be moved aside once before the
  first install, as with every other managed target.

## Related Research

* [Dotfile symlink patterns in popular repositories](../research/0001-dotfiles-symlink-patterns.md)
