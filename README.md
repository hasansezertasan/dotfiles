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

The `Brewfile` declares casks as well as formulae. It is a curated list rather
than a dump of everything installed, so an app has to be added deliberately.

Formulae from the personal tap need that tap's trust declared in the same file.
Homebrew will not load a formula from an untrusted third-party tap and
`brew bundle` cannot prompt, so a bare `tap` line makes the bootstrap fail.
Adding a formula to the tap means adding it to both the install list and the
`trusted:` list.
Zed is required rather than optional: the macOS settings below make it the
default handler for a list of file types, which needs the app present.

## Symlinks

Configuration is grouped into explicit Stow packages. The link script currently
manages `atuin`, `claude`, `gh`, `git`, `mise`, and `zsh`; it intentionally does
not discover packages so that adding a directory to the repository cannot
unexpectedly change `$HOME`.

`~/.config/zed` is still unmanaged. Zed rewrites its own `settings.json` when
settings are changed in the interface, and whether it preserves a symlink has
not been verified. Confirm it before adding the package: change any setting in
Zed, then check the path is still a link.

```sh
ls -l ~/.config/zed/settings.json
```

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

The same applies to any newly managed path. Stow abandons the whole invocation
on a conflict, so nothing is linked until every conflicting target has been
moved aside.

### Command-line tools

The `gh`, `mise`, and `atuin` packages link a single configuration file each:
`~/.config/gh/config.yml`, `~/.config/mise/config.toml`, and
`~/.config/atuin/config.toml`. All three tools write to their configuration
through the symlink, so `gh config set`, `mise use -g`, and `atuin config set`
keep working and their changes appear as repository changes.

`~/.config/gh/hosts.yml` is deliberately excluded and gitignored. GitHub CLI
keeps the token in the system keyring when one is available, but writes it into
that file when one is not, so the path must never become tracked.

Because Git records only `644` and `755`, linking a configuration file that was
`600` makes it group- and world-readable. That is acceptable for these three,
which hold no credentials, and is a further reason to keep `hosts.yml` out.

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

`link.sh` has a behavioural test that runs it against a scratch `HOME`, so it
never touches the real home directory:

```sh
./link_test.sh
```

It checks that `install` creates every expected link, that `--no-folding`
leaves `~/.claude` and `~/.config` as real directories, that `uninstall`
reverses cleanly, and that an existing file is refused rather than overwritten
or adopted.

The `CI` workflow runs all of these on every push to `main` and on every pull
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
