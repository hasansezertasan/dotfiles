# dotfiles

Personal macOS configuration, managed with GNU Stow.

## Setup

With Homebrew, Git, and Zsh available, run:

```sh
./bootstrap.sh
```

The bootstrap installs missing Homebrew formulae, checks for symlink conflicts,
clones Oh My Zsh when needed, activates the managed links, and applies the macOS
settings below. It preserves valid existing installations and refuses to
overwrite conflicting paths.

## Symlinks

Configuration is grouped into explicit Stow packages. The link script currently
manages `claude` and `zsh`; it intentionally does not discover packages so that
adding a directory to the repository cannot unexpectedly change `$HOME`.

Preview changes before installing:

```sh
./link.sh check
```

Manage the links with:

```sh
./link.sh install
./link.sh restow
./link.sh uninstall
```

The script uses Stow's `--no-folding` option. Files inside shared directories
such as `~/.claude` and `~/.config` are linked individually, leaving those
directories available for application-owned state.

Existing files and incorrect links are treated as conflicts. The script never
overwrites or adopts them; move or back them up explicitly, then rerun it.

### Zsh

The `zsh` package links `.zshrc` and the portable configuration fragments under
`~/.config/zsh/conf.d`. Machine-specific configuration and secrets can be put in
the untracked `~/.zshrc.local`, which is sourced last when present.

`.zprofile` is deliberately unmanaged because it currently contains local
OrbStack and TinyTeX setup. `.zshenv` should only be added if a setting must be
available to every Zsh process, including non-interactive shells.

## macOS settings

After installing shell dependencies and links, `bootstrap.sh` applies macOS
preferences. It is executable configuration, not a dotfile, and is therefore
not part of any Stow package.

## Agent skills

Project skills are declared in `skills-lock.json`. Restore their generated,
gitignored files with:

```sh
npx skills experimental_install
```
