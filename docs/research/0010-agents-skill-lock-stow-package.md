# Stow boundary for the global Skills CLI manifest

Research snapshot: 2026-09-10 on macOS 26.

## Executive conclusion

The Skills CLI has one portable global configuration file:
`~/.agents/.skill-lock.json`. It records installed-skill provenance and can be
managed safely as a narrow Stow package; the adjacent `skills/` directory is
generated installed content and remains unmanaged.

## Inventory method

The `~/.agents` directory was enumerated. The manifest was checked for file
size, mode, credential-related terms, and absolute home-directory paths. The
installed `skills` CLI was inspected to identify its global manifest location
and then run against a disposable home directory and a symlinked manifest.

| File or directory | Size / mode | Classification | Decision |
| --- | --- | --- | --- |
| `~/.agents/.skill-lock.json` | 50,792 bytes, `644` | portable-config | Manage |
| `~/.agents/skills/` | generated installed skill trees | generated-state | Exclude |

The manifest contains sources, source URLs, skill paths, hashes, plugin names,
and installation timestamps. It contains no matched credential terms or
absolute `/Users/hasansezertasan` paths. Its existing `644` mode is compatible
with Git checkout mode.

## Symlink write-through

The Skills CLI derives the global manifest path as
`~/.agents/.skill-lock.json` (unless `XDG_STATE_HOME` is configured). A
disposable home used a symlink at that path pointing to a repository copy. The
side-effect-contained command below installed one publicly available skill into
the disposable `~/.agents/skills/` directory:

```sh
HOME="${SCRATCH}/cfg" skills add mattpocock/skills --global \
  --skill ask-matt --agent universal --copy --yes
```

After the command, the manifest path was still a symlink and its repository
target contained the new `ask-matt` record. Therefore the CLI writes through
the link rather than replacing it.

## Package boundary

The `agents` Stow package contains only
`agents/.agents/.skill-lock.json`. The existing `.gitignore` rule excludes
`.agents/skills/`, preventing generated skill content from being staged while
allowing the lock manifest to remain tracked.

## Existing-manifest migration

Stow normally rejects a regular target file, so an existing Skills CLI manifest
would otherwise abort the whole multi-package install. `link.sh` detects that
specific target and invokes Stow's `--adopt` mode for the `agents` package
alone. Adoption moves the local manifest into the package path and replaces it
with the expected symlink. The remaining packages are still stowed without
`--adopt`, so their conflicts remain protective. Simulation with `link.sh
check` previews this adoption without changing either manifest.
