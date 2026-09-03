# dotfiles

Personal macOS configuration, managed with GNU Stow.

## Setup

With Homebrew, Git, and Zsh available, run:

```sh
./bootstrap.sh
```

The bootstrap installs the `Brewfile` dependencies, checks for symlink
conflicts, clones Oh My Zsh when needed, activates the managed links, and
applies the macOS settings below. It preserves valid existing installations and
refuses to overwrite conflicting paths.

Homebrew packages are declared in the repository's `Brewfile` and installed with
`brew bundle`. The bootstrap passes `--no-upgrade`, so already-installed
formulae keep their current version. Inspect or upgrade them directly with:

```sh
brew bundle check --file Brewfile
brew bundle upgrade --file Brewfile
```

## Symlinks

Configuration is grouped into explicit Stow packages. The link script currently
manages `claude`, `git`, and `zsh`; it intentionally does not discover packages
so that adding a directory to the repository cannot unexpectedly change `$HOME`.

`~/.config/gh`, `~/.config/zed`, `~/.config/atuin`, and `~/.config/mise` are
candidates for future packages. They are unmanaged for now because each needs
checking first: `gh/hosts.yml` holds an authentication token, and the rest are
rewritten by their own applications rather than only by hand.

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

### Git

The `git` package links `~/.gitconfig`. Git resolves the symlink when writing,
so `git config --global` edits the tracked file in place and shows up as a
repository change instead of replacing the link.

An existing `~/.gitconfig` is a conflict like any other target. Move it aside
once, then install:

```sh
mv ~/.gitconfig ~/.gitconfig.backup
./link.sh install
```

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

## Checks

Tracked shell scripts are checked with ShellCheck, and the Zsh package gets a
parse-only check:

```sh
git ls-files -z '*.sh' | xargs -0 shellcheck
git ls-files -z 'zsh/.zshrc' 'zsh/*.zsh' | xargs -0 -n1 zsh -n
```

The `CI` workflow runs both commands on every push to `main` and on every pull
request. Each uses a pathspec rather than a fixed file list, so a new script or
Zsh fragment is covered without editing the workflow.

`zsh -n` needs one invocation per file. It reads a single script and treats any
further arguments as positional parameters, so passing several files at once
would silently check only the first — hence `xargs -n1`.

## Agent skills

Project skills are declared in `skills-lock.json`. Restore their generated,
gitignored files with:

```sh
npx skills experimental_install
```
