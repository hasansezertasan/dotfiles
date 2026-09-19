# Stow candidate scan

Research snapshot: 2026-09-11 on macOS 26.6, with a supplementary coverage and
verification pass on 2026-09-19.

## Executive conclusion

No candidate is ready to add. bd met every technical criterion — 111 bytes of
portable configuration, no credentials, and verified to write through a symlink
— but it is withdrawn: the tool is no longer in use as of 2026-09-19, so there
is no configuration worth restoring on another machine. The verification is
kept below as evidence, should bd ever come back.

Nothing else qualifies either. Twenty-seven tools were examined on 2026-09-11 — nine
with configuration on disk and eighteen Brewfile tools with none — and each of
the eight non-viable examined locations is excluded for a reason of its own:
credentials (gcloud, codexbar, VS Code), an external Git repository (nvim),
generated state (herdr), a cache directory (cobo), databases with no
configuration files (Raycast), and an empty placeholder file (Ghostty).

That first pass did not reach every Brewfile entry. The supplementary pass
records the remaining eighteen, so all 47 declarations now have an outcome:
seven are already-managed packages, twenty-two appear in the tables below, and
eighteen are covered under Brewfile coverage.

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

That list is the 2026-09-11 state. Since then `delegate-skills` has been added
and `codex` removed — see ADR 0017 — but neither changes any finding here:
`delegate-skills` is not a Brewfile entry, and Codex's hook definition was
already outside the scope of this scan.

## Findings by tool

### Tools with configuration examined

| Tool | Location | Size | Classification | Viable |
| --- | --- | --- | --- | --- |
| nvim | `~/.config/nvim/` | 220K | External git repo | No |
| gcloud | `~/.config/gcloud/` | 93M | Credentials | No |
| herdr | `~/.config/herdr/` | 18K | Generated state | No |
| bd | `~/.config/bd/config.yaml` | 111B | Portable config | No — tool no longer used |
| VS Code | `~/Library/.../Code/User/` | — | Mixed (credentials) | No |
| Ghostty | `~/Library/.../com.mitchellh.ghostty/` | — | Empty placeholder | No |
| Raycast | `~/Library/.../com.raycast.macos/` | — | Databases only | No |
| codexbar | `~/.config/codexbar/` | 7K | Credentials | No |
| cobo | `~/.cobo/` | — | Cache (gitignore templates) | No |

### Tools with no configuration found

The following Brewfile tools have no user configuration on disk:

btop, dockutil, duti, fzf, jq, mole, ripgrep, shellcheck, starship,
tailscale, tmux, x-cmd, yazi, zoxide, hwid, nur, ocom, peta.

`skills` is not among them. The Skills CLI owns `~/.agents/.skill-lock.json`,
which the `agents` package already manages — see ADR 0016 — so it belongs with
the already-managed tools rather than the unconfigured ones.

## Tool-specific notes

### nvim — externally version-controlled

The nvim directory contains its own `.git/` repository. It is already version
controlled externally and should not be absorbed into this dotfiles repo as a
Stow package. If consolidation is desired, add it as a Git submodule instead.

### gcloud — credential-heavy

Contains `access_tokens.db`, `credentials.db`, and
`application_default_credentials.json`. Also contains a Python virtual
environment (93 MB). None of this is portable or safe to track.

### bd — verified symlink-safe, then withdrawn

bd is no longer in use as of 2026-09-19, so it is not a candidate regardless of
the result below. The verification stands on its own and is kept for reference.

`bd config set` does not respect `XDG_CONFIG_HOME` or any redirect variable,
and always writes to `~/.config/bd/config.yaml`. That rules out the preferred
scratch-directory test, but not testing as such: the file is 111 bytes and the
write is driven by `bd metrics on|off`, so it can be backed up, exercised, and
restored.

Tested 2026-09-19 with bd 1.2.2 (Homebrew). The real config was moved outside
`~/.config/bd`, a symlink left in its place, and `bd metrics on` run:

* The symlink survived the write — `~/.config/bd/config.yaml` was still a link
  afterwards, not a file bd had replaced.
* `metrics.disabled` changed from `true` to `false` in the target file outside
  the configuration directory, so the write followed the link.
* `bd metrics off` restored the original value, and the original file was put
  back byte-identical with its `600` mode intact.

bd therefore satisfies the criterion ADR 0004 set and ADR 0009 applied, which
settles the question the 2026-09-11 pass left open. It is not being added, for
the reason given at the top of this section. The
config file (111 bytes) contains only metrics settings with no credentials. As
recorded on 2026-09-11 it read:

```yaml
metrics:
    disabled: false
    endpoint: https://gastownhall-eventsapi.com/mp/collect
    notice_shown: true
```

By 2026-09-19 `metrics.disabled` was `true`, set in the ordinary course of
using the tool, and that is the value the test started from: `bd metrics on`
moved it to `false` and `bd metrics off` returned it to `true`. Only that field
differs between the two snapshots.

A `BD_CONFIG_DIR` or similar mechanism would make the behaviour re-testable in
a scratch directory, which is the only thing its absence now costs.

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

## Brewfile coverage

Supplementary pass, 2026-09-19. The 2026-09-11 tables cover twenty-two of the
forty Brewfile entries that are not already managed. These are the other
eighteen. This pass records only whether configuration exists and what kind it
is; no symlink-safety testing was done, because nothing here reached the point
of needing it.

| Entry | Configuration found | Classification | Viable |
| --- | --- | --- | --- |
| chatgpt | `~/Library/Application Support/com.openai.chat` | App-managed state | No |
| cloudflare-warp | `com.cloudflare.1dot1dot1dot1.macos.plist` | Preferences plist | No |
| dbeaver-community | `org.jkiss.dbeaver.core.product.plist` | Preferences plist | No |
| google-chrome | `com.google.Chrome.plist`, `~/Library/.../Google/Chrome` | App-managed profile | No |
| google-drive | `com.google.drivefs*.plist` | Preferences plist | No |
| openvpn-connect | `~/.openvpn/*.ovpn`, `~/Library/.../OpenVPN Connect` | Credentials (VPN profile) | No |
| orbstack | `~/.orbstack/config/docker.json` (4B) | Empty placeholder beside `bin/`, `log/`, install id | No |
| slack | `~/Library/.../Slack`, `com.tinyspeck.slackmacgap.plist` | App-managed state | No |
| spotify | `~/Library/.../Spotify`, `com.spotify.client.plist` | App-managed state | No |
| stats | `~/Library/.../Stats`, `eu.exelban.Stats.plist` | Preferences plist | No |
| tailscale-app | `io.tailscale.ipn.macsys.plist` | Preferences plist | No |
| discord | none | No configuration on disk | No |
| iina | none | No configuration on disk | No |
| notunes | none | No configuration on disk | No |
| whatsapp | none | No configuration on disk | No |
| zen | none | No configuration on disk | No |
| meta-package-manager | none (`~/.config/mpm` absent) | No configuration on disk | No |
| stow | none (`~/.stowrc` absent) | No configuration on disk | No |

OrbStack was the one entry with a configuration subtree worth opening, so it was
inventoried per file rather than rejected by directory. `~/.orbstack/config/`
holds a single file, `docker.json`, of four bytes — `{}`, an empty object, with
no credential patterns. A narrow package could manage that one file the way the
`olink` package manages its pins file, but there is nothing in it to manage yet.
The surrounding `bin/`, `k8s/`, `log/` and `.installid` are generated state and
would stay outside any such package. Revisit if Docker settings are ever written
there; symlink-safety testing was not attempted, because an empty file gives
nothing to verify a write against.

`~/.openvpn` holds a `.ovpn` profile, which carries embedded credentials and is
excluded for the same reason as gcloud.

Preferences plists are excluded throughout: they are binary, rewritten wholesale
by `cfprefsd` rather than by an application writing a file, and they mix durable
settings with window state.

## Symlink safety

| Tool | Redirect variable | Write command | Status |
| --- | --- | --- | --- |
| bd | None found | `bd metrics on` / `off` | Verified in place — writes through the link, but withdrawn |

bd was the only candidate with portable configuration, and it writes through a
symlink. The missing redirect variable means the check has to be run against
the real file rather than a scratch copy. The tool is no longer used, so the
result is recorded rather than acted on.

## Next steps

**Ready to add:** None.

**Withdrawn:**
- `bd` — technically viable, one managed file verified symlink-safe on
  2026-09-19, but the tool is no longer used. Reconsider only if it returns.

**Needs credential cleanup before consideration:**
- VS Code — remove or externalize hardcoded API keys and passwords from
  `settings.json`, then reassess.

**Not viable:**
- the eighteen Brewfile entries under Brewfile coverage — app-managed state,
  preferences plists, credentials, or no configuration at all
- nvim — already has its own git repository
- gcloud — credential store, not config
- herdr — only logs and session state
- codexbar — credential store
- cobo — cache directory only
- Ghostty — no config exists yet
- Raycast — database-driven, no config files

**No config to manage:**
- btop, dockutil, duti, fzf, jq, mole, ripgrep, shellcheck, starship,
  tailscale, tmux, x-cmd, yazi, zoxide, hwid, nur, ocom, peta
