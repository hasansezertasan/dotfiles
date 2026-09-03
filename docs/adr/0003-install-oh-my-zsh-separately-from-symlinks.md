# Install Oh My Zsh Separately from Symlinks

## Context and Problem Statement

The tracked Zsh configuration loads Oh My Zsh and enables integrations for
Starship, Zoxide, and mise. A fresh machine needs those dependencies before the
configuration is useful, but `link.sh` currently has the narrower responsibility
of managing links without downloading or executing third-party software.

## Considered Options

* Clone Oh My Zsh directly and document Homebrew dependencies as a separate
  setup step
* Run the official Oh My Zsh installer with `--unattended --keep-zshrc`
* Download and install shell dependencies from `link.sh`
* Leave dependency installation implicit

## Decision Outcome

Chosen option: "Clone Oh My Zsh directly and document Homebrew dependencies as
a separate setup step", because it makes fresh-machine setup explicit while
preserving both the repository-managed `.zshrc` and `link.sh` as a deterministic
symlink manager.

Clone the upstream repository only when the configured `ZSH` directory is
absent. Do not run the installer: even with `--keep-zshrc`, it creates a new
`.zshrc` when none exists and could create a conflict before Stow activates the
managed link. Install GNU Stow, Starship, Zoxide, and mise with Homebrew before
activating the links.

### Consequences

* Good, because cloning only the framework cannot replace the
  repository-managed `.zshrc`.
* Good, because rerunning the guarded installation block skips an existing Oh
  My Zsh checkout.
* Good, because shell dependencies are discoverable in one setup section.
* Good, because link management remains independent of network availability.
* Bad, because setup still has a manual dependency-installation step.
* Bad, because the checkout follows the upstream default branch rather than a
  repository-pinned revision.

## Related Research

* [Oh My Zsh installation](../research/0003-oh-my-zsh-installation.md)
