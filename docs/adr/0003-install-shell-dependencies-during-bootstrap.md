# Install Shell Dependencies during Bootstrap

## Context and Problem Statement

The tracked Zsh configuration loads Oh My Zsh and enables integrations for
Starship, Zoxide, and mise. A fresh machine needs those dependencies and the
Stow links before the configuration is useful. Keeping these as separate manual
steps makes `bootstrap.sh` an incomplete entry point for configuring a machine.

## Considered Options

* Install shell dependencies and managed links from `bootstrap.sh`
* Document shell dependency and link commands as separate manual steps
* Run the official Oh My Zsh installer from `bootstrap.sh`
* Leave dependency installation implicit

## Decision Outcome

Chosen option: "Install shell dependencies and managed links from
`bootstrap.sh`", because one command can establish the required shell
environment before applying the existing macOS preferences.

The bootstrap verifies that Homebrew, Git, and Zsh are available, installs
missing formula-backed commands, previews the Stow operation, clones Oh My Zsh
directly when needed, and activates the links. It preserves valid existing Oh
My Zsh installations and fails on conflicting target paths rather than
overwriting them.

Direct cloning avoids the upstream installer's `.zshrc` side effects. Symlink
management remains delegated to `link.sh`, keeping package selection and Stow
flags in one place.

### Consequences

* Good, because `bootstrap.sh` is the single entry point for shell dependencies,
  links, and macOS preferences.
* Good, because repeated runs skip commands and framework files that are already
  installed.
* Good, because link and Oh My Zsh conflicts stop the bootstrap instead of being
  overwritten.
* Good, because `link.sh` remains independently usable for link maintenance.
* Bad, because bootstrap now requires network access when dependencies are
  missing.
* Bad, because the Oh My Zsh checkout follows the upstream default branch rather
  than a repository-pinned revision.
* Bad, because a later macOS preference failure can leave earlier dependency and
  link changes applied.

## Related Research

* [Oh My Zsh installation](../research/0003-oh-my-zsh-installation.md)
