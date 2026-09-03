# dotfiles

Personal macOS configuration, managed with GNU Stow.

## Setup

With Homebrew and Git available, install the command-line dependencies used by
the link script and configured Zsh plugins:

```sh
brew install stow starship zoxide mise
```

Install Oh My Zsh when it is not already present:

```sh
omz_dir="${ZSH:-${HOME}/.oh-my-zsh}"
if [[ -r "${omz_dir}/oh-my-zsh.sh" ]]; then
  echo "Oh My Zsh is already installed at ${omz_dir}"
elif [[ -e "${omz_dir}" || -L "${omz_dir}" ]]; then
  echo "Cannot install Oh My Zsh: ${omz_dir} already exists" >&2
else
  git clone https://github.com/ohmyzsh/ohmyzsh.git "${omz_dir}"
fi
unset omz_dir
```

Cloning the framework directly avoids creating or replacing the `.zshrc`
managed by this repository. An existing target is preserved and reported as a
conflict unless it contains a readable `oh-my-zsh.sh` installation.

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

`bootstrap.sh` applies macOS preferences. It is executable configuration, not a
dotfile, and is therefore not part of any Stow package.

## Agent skills

Project skills are declared in `skills-lock.json`. Restore their generated,
gitignored files with:

```sh
npx skills experimental_install
```
