# Manage Dotfiles with GNU Stow

## Context and Problem Statement

Portable configuration must be versioned in this repository while remaining at
the paths expected by tools in `$HOME`. Installation must be repeatable, must
not silently replace existing configuration, and must avoid placing mutable
application state inside the repository.

## Considered Options

* Manage explicit topic packages with GNU Stow
* Maintain a custom symlink manifest and installer
* Copy configuration files into `$HOME`
* Keep a regular `.zshrc` that sources files directly from the repository

## Decision Outcome

Chosen option: "Manage explicit topic packages with GNU Stow", because Stow
provides an established and reversible symlink lifecycle without requiring a
repository-specific link implementation.

The repository directly links `.zshrc`, loads portable Zsh fragments from
`~/.config/zsh/conf.d`, and reserves `~/.zshrc.local` for untracked local
configuration. The link script names packages explicitly and uses
`--no-folding` so shared directories remain ordinary directories.

### Consequences

* Good, because repository changes become active without a copy or generation
  step.
* Good, because Stow detects conflicts and supports repeatable install, restow,
  and uninstall operations.
* Good, because file-level links keep credentials, caches, and application state
  outside the repository.
* Bad, because GNU Stow is an installation prerequisite.
* Bad, because an existing target requires an explicit backup or migration.

## Related Research

* [Dotfile symlink patterns in popular repositories](../research/0001-dotfiles-symlink-patterns.md)
