# Dotfile symlink patterns in popular repositories

Research snapshot: 2026-09-03. Popularity and activity figures below are approximate GitHub star counts and default-branch head dates observed on that date. The implementation claims link to repository-owned code or documentation at the commit inspected.

## Executive conclusion

Yes: for this repository, symlink the repo-managed `.zshrc` directly to `~/.zshrc`.

That is the clearest convention in the active examples reviewed. A good design is:

- keep portable shell configuration in the tracked `.zshrc`;
- have that file conditionally source one untracked, machine-local file such as `~/.zshrc.local`;
- let an idempotent installer create and audit the link;
- never silently overwrite an existing file or wrong link;
- link only explicitly declared configuration files/directories, not broad directories that mix config with credentials, caches, history, or application state.

A tiny regular `~/.zshrc` that only sources a file in the repository is also defensible, but the surveyed repositories do not show a compelling advantage for that extra indirection. It leaves an unmanaged bootstrap file in `$HOME` and requires special update logic. Generated/copied files are useful when templating is truly required, but otherwise drift from their source.

## Repository evidence

| Repository | Popularity/activity snapshot | Installation model | What happens to `.zshrc` |
| --- | ---: | --- | --- |
| [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) | ~31.5k stars; head 2024-04-09 | Copy, not links. Its README says the bootstrapper copies files to `$HOME`, and the script uses `rsync ... . ~`. It prompts because this may overwrite existing files. [README](https://github.com/mathiasbynens/dotfiles/blob/b7c7894e7bb2de5d60bfb9a2f5e46d01a61300ea/README.md#using-git-and-the-bootstrap-script), [bootstrap](https://github.com/mathiasbynens/dotfiles/blob/b7c7894e7bb2de5d60bfb9a2f5e46d01a61300ea/bootstrap.sh#L9-L23) | Copied with the other dotfiles. This is the notable high-popularity counterexample; edits and pulls can diverge until bootstrap is rerun. |
| [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles) | ~8.2k stars; head 2026-08-11 | Uses `rcm`; `rcup` creates home-directory symlinks, supports exclusions, and composes a second `~/dotfiles-local` source directory. [installation](https://github.com/thoughtbot/dotfiles/blob/3c80686c04d41cbfc8302c9a7c394c094babf148/README.md#install), [rcm settings](https://github.com/thoughtbot/dotfiles/blob/3c80686c04d41cbfc8302c9a7c394c094babf148/rcrc) | The repository's `zshrc` becomes `~/.zshrc`; it conditionally sources `~/.zshrc.local`, plus modular zsh configs. [zshrc local hook](https://github.com/thoughtbot/dotfiles/blob/3c80686c04d41cbfc8302c9a7c394c094babf148/zshrc#L45-L49), [customization docs](https://github.com/thoughtbot/dotfiles/blob/3c80686c04d41cbfc8302c9a7c394c094babf148/README.md#make-your-own-customizations) |
| [holman/dotfiles](https://github.com/holman/dotfiles) | ~7.8k stars; head 2026-06-25 | Topic-based custom installer. Files named `*.symlink` are linked into `$HOME` without the suffix. [layout documentation](https://github.com/holman/dotfiles/blob/9a90082b61fa5659789b9d41544c19098825a3ca/README.md#topical), [installer](https://github.com/holman/dotfiles/blob/9a90082b61fa5659789b9d41544c19098825a3ca/script/bootstrap#L76-L156) | `zsh/zshrc.symlink` is linked as `~/.zshrc`; the README explicitly calls it the main file to customize. The installer detects an already-correct link and otherwise asks whether to skip, overwrite, or back up. [install notes](https://github.com/holman/dotfiles/blob/9a90082b61fa5659789b9d41544c19098825a3ca/README.md#install) |
| [paulirish/dotfiles](https://github.com/paulirish/dotfiles) | ~4.4k stars; head 2026-08-30 | Custom script finds top-level dotfiles plus selected directories and links them into `$HOME`. It is intended to be repeatable, recognizes correct links, and prompts before replacing conflicts. [README](https://github.com/paulirish/dotfiles/blob/33978fdb5ac5bb3d939be3077ae17c0db7aad58b/README.md#manual-run), [link implementation](https://github.com/paulirish/dotfiles/blob/33978fdb5ac5bb3d939be3077ae17c0db7aad58b/symlink-setup.sh#L119-L170) | `.zshrc` is among the top-level dotfiles selected by the script, so it is linked directly to `~/.zshrc`. [repository `.zshrc`](https://github.com/paulirish/dotfiles/blob/33978fdb5ac5bb3d939be3077ae17c0db7aad58b/.zshrc) |
| [webpro/dotfiles](https://github.com/webpro/dotfiles) | ~1.2k stars; head 2026-07-22 | GNU Stow links the `runcom` package into `$HOME` and the `config` package into `$XDG_CONFIG_HOME`. Before linking, regular conflicting runcom files are renamed with `.bak`; `make unlink` removes links and restores backups. [README](https://github.com/webpro/dotfiles/blob/01368ed3ba9506b9634541d4387e5caed28c8ed4/README.md#installation), [Makefile](https://github.com/webpro/dotfiles/blob/01368ed3ba9506b9634541d4387e5caed28c8ed4/Makefile#L48-L61) | The current repo manages Bash rather than Zsh, but it demonstrates two useful operational patterns: separate `$HOME` and XDG link roots, and reversible backup/unlink behavior. |
| [anishathalye/dotfiles](https://github.com/anishathalye/dotfiles) | ~750 stars; head 2026-08-26 | Uses the author's Dotbot installer with an explicit source-to-target link manifest and cleanup of dead links. [manifest](https://github.com/anishathalye/dotfiles/blob/f7e7ecb638208c51941955adf5f2cc80a00e415b/.install.conf.yaml), [installer](https://github.com/anishathalye/dotfiles/blob/f7e7ecb638208c51941955adf5f2cc80a00e415b/install) | The manifest explicitly links `~/.zshrc`; the file exposes before/after local hooks (`~/.zshrc_local_before` and `~/.zshrc_local_after`) and shared shell hooks. [zshrc](https://github.com/anishathalye/dotfiles/blob/f7e7ecb638208c51941955adf5f2cc80a00e415b/zshrc), [customization docs](https://github.com/anishathalye/dotfiles/blob/f7e7ecb638208c51941955adf5f2cc80a00e415b/README.md#local-customizations) |

The sample is not a statistical census, but it spans home-grown scripts, `rcm`, GNU Stow, and Dotbot. Four of the five repositories that currently manage Zsh directly symlink `.zshrc`; the remaining one copies all dotfiles.

## What this repository should symlink

Use an explicit package list rather than stowing every top-level directory. Symlink portable, declarative configuration whose repository version should be authoritative:

- `~/.zshrc` and, only if needed, `~/.zprofile` / `~/.zshenv`;
- `~/.gitconfig`, with identity, signing keys, and work-only settings included from an untracked `~/.gitconfig.local`;
- terminal and editor configuration such as `~/.tmux.conf`, `~/.config/nvim`, `~/.config/ghostty`, and `~/.config/starship.toml` when those files exist in the repo;
- small, wholly declarative application directories, or preferably their individual files.

Do not symlink secrets or mutable state:

- SSH private keys, `~/.gnupg`, cloud credentials, tokens, and `.env` files;
- shell history, caches, logs, sessions, sockets, plugin downloads, or generated completions;
- all of `~/.config`, `~/.local`, or another mixed-purpose directory;
- app directories that combine portable settings with machine-local databases/runtime data. Link selected files inside them instead.

## Recommended link behavior

1. Clone to one documented, stable location such as `~/.dotfiles`. GNU Stow normally creates relative links; after moving the clone, run Stow again from the new location.
2. Keep one package per topic and pass an explicit package list to Stow. Do not use `stow *`: this prevents `README.md`, bootstrap code, or a newly added top-level directory from unexpectedly becoming live configuration.
3. Use `--no-folding`, especially for mixed-use directories such as `~/.config` and `~/.claude`. This makes Stow link the managed files instead of replacing a whole directory with one link into the repository, where an application could then write credentials, caches, or state.
4. For each target, distinguish all relevant states using both `-e` and `-L` so broken symlinks are handled:
   - missing: create the link;
   - symlink already resolving to the intended source: no-op;
   - wrong or broken symlink: report it and back up or replace only under an explicit policy;
   - regular file/directory: default to a timestamped backup or refuse; never silently delete it.
5. Make install idempotent and add `check`/`doctor` output for missing, correct, conflicting, and broken links. Preview with `stow --simulate --verbose=2 --no-folding --target="$HOME" <packages...>`.
6. Provide a reversible unlink operation with `stow --delete --no-folding --target="$HOME" <packages...>`. Do not delete a path merely because it belongs to a package.
7. Let Stow refuse conflicts by default. A wrapper may offer a timestamped backup, but only as an explicit migration step. Avoid automating `stow --adopt`: it moves the target's current contents into the repository and therefore needs an immediate, careful `git diff` review.
8. Do not use a blanket `ln -sf` for directories: platform differences and existing-directory semantics can create a link *inside* the directory rather than replace the target. Resolve and validate the exact destination first.

## Suggested `.zshrc` shape

The symlink target should be a small orchestrator, while substantial configuration can live in tracked fragments:

```zsh
# ~/.zshrc -> ~/.dotfiles/zsh/.zshrc
config_dir="${HOME}/.config/zsh/conf.d"

for config in "${config_dir}/"*.zsh(N); do
  source "${config}"
done

# Machine-specific and secret values stay outside Git.
[[ -r "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"
```

The fragments can live under `zsh/.config/zsh/conf.d` in the package and be linked into the path above. This preserves the main benefit of direct symlinks—repository edits and pulls take effect in the next shell—without hard-coding the repository's checkout path, while retaining a clear escape hatch for per-machine configuration. Keep environment variables needed by every zsh process in `.zshenv` only when truly necessary; interactive aliases, prompt, completions, and tool initialization belong in `.zshrc`.
