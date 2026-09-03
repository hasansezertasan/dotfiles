# Oh My Zsh installation for Stow-managed Zsh configuration

Research snapshot: 2026-09-03. The Oh My Zsh source links below are pinned to
the upstream commit inspected.

## Executive conclusion

Prefer Oh My Zsh's documented manual installation step: clone the repository
directly into `${ZSH:-${HOME}/.oh-my-zsh}`. This repository already owns the
Zsh configuration and does not need the upstream installer to create a
`.zshrc`, change the login shell, or start a new shell:

```sh
git clone https://github.com/ohmyzsh/ohmyzsh.git "${ZSH:-${HOME}/.oh-my-zsh}"
```

The direct clone is the first step in Oh My Zsh's official
[manual installation instructions](https://github.com/ohmyzsh/ohmyzsh/blob/9112b53fa8b5ab556c7c893aa8be8a247ac512a0/README.md#manual-installation).
It has no `.zshrc` side effect and is consequently a better fit for an
automated setup whose `.zshrc` is owned by GNU Stow.

If the official installer is used instead, install the Stow-managed `.zshrc`
first and pass both `--unattended` and `--keep-zshrc`:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
  "" --unattended --keep-zshrc
```

Those flags have separate responsibilities. `--unattended` prevents the
installer from changing the login shell or launching Zsh and disables overwrite
confirmation; `--keep-zshrc` preserves an existing `.zshrc`. Using
`--unattended` without `--keep-zshrc` would therefore be unsafe for this
repository's managed link. These behaviors are defined by the
[installer options and argument parser](https://github.com/ohmyzsh/ohmyzsh/blob/9112b53fa8b5ab556c7c893aa8be8a247ac512a0/tools/install.sh#L17-L40).

The order matters: the installer's keep branch applies only when `.zshrc`
already exists as a file or symlink. If the path is absent, it still creates a
new `.zshrc` from its template. The repository should therefore run
`./link.sh install` first and invoke the Oh My Zsh installer afterward. See the
upstream [`setup_zshrc` implementation](https://github.com/ohmyzsh/ohmyzsh/blob/9112b53fa8b5ab556c7c893aa8be8a247ac512a0/tools/install.sh#L354-L409).

## Idempotency and prerequisites

The upstream installer is not rerun-idempotent: it exits with an error if the
target `$ZSH` directory already exists. Repository automation should skip the
installer when `${ZSH:-${HOME}/.oh-my-zsh}/oh-my-zsh.sh` is already readable,
rather than rerunning it. The existing Zsh fragment uses the same readable-file
condition before sourcing the framework. See the installer's
[existing-directory check](https://github.com/ohmyzsh/ohmyzsh/blob/9112b53fa8b5ab556c7c893aa8be8a247ac512a0/tools/install.sh#L562-L582).

Oh My Zsh requires Zsh, Git, and either `curl`, `wget`, or `fetch` to retrieve
the installer. The script explicitly rejects a missing Zsh or Git executable;
the project README lists the same
[prerequisites](https://github.com/ohmyzsh/ohmyzsh/blob/9112b53fa8b5ab556c7c893aa8be8a247ac512a0/README.md#prerequisites).

## Plugin command requirements

All five names in `plugins=(git brew starship zoxide mise)` are bundled Oh My
Zsh plugins, so they require no separate plugin clone. Their corresponding
commands still need to be available for the integrations to be useful:

- `git` is already required by the Oh My Zsh installer. The bundled
  [Git plugin](https://github.com/ohmyzsh/ohmyzsh/blob/9112b53fa8b5ab556c7c893aa8be8a247ac512a0/plugins/git/README.md)
  supplies aliases and functions around that executable.
- `brew` requires Homebrew. The bundled
  [Brew plugin](https://github.com/ohmyzsh/ohmyzsh/blob/9112b53fa8b5ab556c7c893aa8be8a247ac512a0/plugins/brew/README.md#shellenv)
  can find Homebrew in its common installation locations and evaluate
  `brew shellenv` when `brew` is not yet on `PATH`.
- The bundled [Starship](https://github.com/ohmyzsh/ohmyzsh/blob/9112b53fa8b5ab556c7c893aa8be8a247ac512a0/plugins/starship/README.md),
  [zoxide](https://github.com/ohmyzsh/ohmyzsh/blob/9112b53fa8b5ab556c7c893aa8be8a247ac512a0/plugins/zoxide/README.md),
  and [mise](https://github.com/ohmyzsh/ohmyzsh/blob/9112b53fa8b5ab556c7c893aa8be8a247ac512a0/plugins/mise/README.md)
  plugins each initialize an external command that must be installed first.

For this macOS and Homebrew-oriented repository, one command installs those
three external tools:

```sh
brew install starship zoxide mise
```

The command is supported by the official Homebrew formulae for
[Starship](https://formulae.brew.sh/formula/starship),
[zoxide](https://formulae.brew.sh/formula/zoxide), and
[mise](https://formulae.brew.sh/formula/mise). Homebrew itself remains an
external prerequisite; its official
[installation documentation](https://docs.brew.sh/Installation) covers current
macOS requirements and initial `brew shellenv` setup.

Enabling the Starship plugin intentionally unsets `ZSH_THEME`, so the configured
`robbyrussell` theme does not control the prompt while that plugin is enabled.
Starship also recommends a Nerd Font-enabled terminal. These are documented in
the [Oh My Zsh Starship plugin](https://github.com/ohmyzsh/ohmyzsh/blob/9112b53fa8b5ab556c7c893aa8be8a247ac512a0/plugins/starship/README.md)
and [Starship prerequisites](https://starship.rs/guide/#prerequisites).

## Recommended bootstrap behavior

1. Verify `zsh`, `git`, and `brew` are available.
2. Install `starship`, `zoxide`, and `mise` with Homebrew. Declare them in the
   repository's `Brewfile` so `brew bundle` installs them alongside the other
   required packages.
3. Preview the repository's Stow links and stop on conflicts.
4. If `${ZSH:-${HOME}/.oh-my-zsh}` is absent, clone the official Oh My Zsh
   repository there. Treat an existing directory without a readable
   `oh-my-zsh.sh` as a conflict rather than overwriting it.
5. Install the repository's Stow links.
6. Apply the macOS preferences and validate with a fresh interactive Zsh
   process.

Implement these steps in `bootstrap.sh`. This preserves the Stow-owned `.zshrc`,
avoids unnecessary installer side effects and duplicate clones, and makes
repeated repository setup runs safe. The guarded installer command remains a
valid alternative, but direct cloning is preferable because the repository
already supplies every configuration step that the installer would otherwise
perform.
