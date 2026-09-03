# Boundaries for additional Stow packages

Research snapshot: 2026-09-03 on macOS 26.

## Executive conclusion

Five additional tools have useful configuration in the home directory, but
only individual portable files belong in Stow. SSH, olink, OpenCode, Zed, and
Codex can be represented as explicit packages without importing their adjacent
credentials, databases, caches, histories, generated integrations, or other
machine state.

## Inventory method

The home directory and known application configuration locations were
inventoried by path, size, mode, and setting names. Credential values were not
printed. Candidate files were then inspected to distinguish user-authored
configuration from generated state.

The repository contained six packages before this work: `atuin`, `claude`,
`gh`, `git`, `mise`, and `zsh`.

## Package boundaries

| Package | Managed files | Deliberately unmanaged |
| --- | --- | --- |
| SSH | `~/.ssh/config` | Keys, `known_hosts`, sockets, and generated host state |
| olink | `~/.config/olink/pins.json` | No adjacent state was found |
| OpenCode | `opencode.jsonc`, `package.json` | `config.json`, plugins, install markers, `node_modules`, auth, logs, databases |
| Zed | `settings.json` | Prompt database and application-support state |
| Codex | `hooks.json` | `config.toml`, auth, histories, sessions, databases, caches, generated state |

The SSH config contains only OrbStack's `Include` directive. Managing that file
does not bring private key material into the repository. Ignore rules use an
allowlist so later copying an existing `.ssh` directory cannot accidentally
stage a key.

The olink pins file is a small user preference containing the `origin` pin and
no credential.

## OpenCode uses a discovered plugin directory

The existing OpenCode `config.json` contains an absolute file URL for the Open
Island plugin. Current OpenCode documentation identifies
`~/.config/opencode/opencode.json(c)` as the global config and states that
JavaScript or TypeScript files in `~/.config/opencode/plugins/` are loaded
automatically. The absolute entry is therefore not portable and does not need
to be reproduced in the managed config.

The canonical schema-only `opencode.jsonc` and the dependency manifest are
managed. The Open Island application remains responsible for its generated
plugin and installer marker, and dependencies remain locally installed.

Sources:

* [OpenCode configuration locations](https://opencode.ai/docs/config/)
* [OpenCode global plugin discovery](https://opencode.ai/docs/plugins/)

## Codex requires a narrower boundary

The Codex directory occupied approximately 845 MB, almost all mutable state.
Its 8.9 KB `config.toml` also mixes user preferences with project trust entries,
trusted hook hashes, generated desktop MCP configuration, versioned local cache
paths, and absolute project paths. Stow works at file granularity, so it cannot
manage only the durable TOML keys.

Only `hooks.json` is managed. Its repeated Open Island command originally
contained the absolute `/Users/hasansezertasan` path; the managed version uses
`$HOME`. The main TOML remains local until Codex offers an include mechanism or
a separate durable-settings file.

## Symlink-write risk

SSH and the OpenCode config are read-oriented. Zed settings, olink pins, and the
Codex hook file may be rewritten by their owning applications or installers.
No safe redirected write command was available to reproduce the symlink test
used in research 0007. The links are being adopted with that limitation made
explicit; Zed's README instructions retain the manual post-save check.

All managed files inspected here contain no credentials. Zed's settings file
was previously mode `600` and becomes readable according to the Git checkout's
normal `644` mode once linked. Codex's mode-`600` main config is not linked,
which preserves its local permission as well as keeping its machine state out.
