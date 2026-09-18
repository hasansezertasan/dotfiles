# Stow candidate scan

Research snapshot: 2026-09-11 on macOS 26.6.

## Executive conclusion

Seventeen candidate locations were scanned. Zero tools are ready to add as Stow
packages. One tool (bd) has portable config but lacks a config-redirect
mechanism, making symlink safety unverifiable without in-place testing. The
remaining candidates contain credentials, are externally version-controlled,
or hold only generated state.

## Inventory method

The following locations were scanned:
- Dotfiles and dot-directories in `$HOME`
- `~/.config/` (XDG config directory)
- `~/Library/Application Support/` for GUI apps in the Brewfile
- Tool-specific locations for each Brewfile formula

Files were classified as portable config, credential, generated state,
cache/database, or machine-specific. Credential detection used grep patterns
for `token`, `api_key`, `secret`, `password`, `oauth`, and key file extensions.

Already-managed packages (from `link.sh`): agents, atuin, claude, codex, gh,
git, mise, olink, opencode, ssh, zed, zsh.

## Findings by tool

### Tools with configuration examined

| Tool | Location | Size | Classification | Viable |
| --- | --- | --- | --- | --- |
| nvim | `~/.config/nvim/` | 220K | External git repo | No |
| gcloud | `~/.config/gcloud/` | 93M | Credentials | No |
| herdr | `~/.config/herdr/` | 18K | Generated state | No |
| bd | `~/.config/bd/config.yaml` | 111B | Portable config | Unknown |
| VS Code | `~/Library/.../Code/User/` | — | Mixed (credentials) | No |
| Ghostty | `~/Library/.../com.mitchellh.ghostty/` | — | Empty placeholder | No |
| Raycast | `~/Library/.../com.raycast.macos/` | — | Databases only | No |
| codexbar | `~/.config/codexbar/` | 7K | Credentials | No |
| cobo | `~/.cobo/` | — | Cache (gitignore templates) | No |

### Tools with no configuration found

The following Brewfile tools have no user configuration on disk:

btop, dockutil, duti, fzf, jq, mole, ripgrep, shellcheck, skills, starship,
tailscale, tmux, x-cmd, yazi, zoxide, hwid, nur, ocom, peta.

## Tool-specific notes

### nvim — externally version-controlled

The nvim directory contains its own `.git/` repository. It is already version
controlled externally and should not be absorbed into this dotfiles repo as a
Stow package. If consolidation is desired, add it as a Git submodule instead.

### gcloud — credential-heavy

Contains `access_tokens.db`, `credentials.db`, and
`application_default_credentials.json`. Also contains a Python virtual
environment (93 MB). None of this is portable or safe to track.

### bd — promising but unverifiable

`bd config set` does not respect `XDG_CONFIG_HOME` or any redirect variable.
The command always writes to `~/.config/bd/config.yaml` regardless of
environment. Without a redirect mechanism, symlink safety cannot be tested in
a scratch directory. An in-place test on the real config would be required.

The config file (111 bytes) contains only metrics settings with no credentials:

```yaml
metrics:
    disabled: false
    endpoint: https://gastownhall-eventsapi.com/mp/collect
    notice_shown: true
```

If bd adds a `BD_CONFIG_DIR` or similar mechanism, this would be a viable
package with one managed file.

### VS Code — credentials in settings

`~/Library/Application Support/Code/User/settings.json` (1378 lines, 60 KB)
contains hardcoded API keys and passwords including:
- `clockify.apiKey`
- `ai-commit.OPENAI_API_KEY`
- Password strings in token color customizations

This config cannot be managed without removing or externalizing the
credentials first. The settings sync feature may be a better approach for
VS Code portability.

### codexbar — full of tokens

`~/.config/codexbar/config.json` stores OAuth access tokens, refresh tokens,
client secrets, and GitHub personal access tokens for multiple providers
(Antigravity, Copilot). Not viable for Stow management.

### Ghostty — no actual config

`~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` exists
but is empty (0 bytes). The standard config location is
`~/.config/ghostty/config` which does not exist. No portable config to manage.

## Symlink safety

| Tool | Redirect variable | Write command | Status |
| --- | --- | --- | --- |
| bd | None found | `bd config set` | Unknown — no redirect to test safely |

No candidates could be verified as symlink-safe. The only tool with portable
config (bd) does not support configuration redirection.

## Next steps

**Ready to add:** None.

**Needs upstream change:**
- `bd` — needs a `BD_CONFIG_DIR` environment variable or similar mechanism
  before symlink safety can be verified.

**Needs credential cleanup before consideration:**
- VS Code — remove or externalize hardcoded API keys and passwords from
  `settings.json`, then reassess.

**Not viable:**
- nvim — already has its own git repository
- gcloud — credential store, not config
- herdr — only logs and session state
- codexbar — credential store
- cobo — cache directory only
- Ghostty — no config exists yet
- Raycast — database-driven, no config files

**No config to manage:**
- btop, dockutil, duti, fzf, jq, mole, ripgrep, shellcheck, skills, starship,
  tailscale, tmux, x-cmd, yazi, zoxide, hwid, nur, ocom, peta
