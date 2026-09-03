# Symlink safety of the candidate application configurations

Research snapshot: 2026-09-03. GitHub CLI 2.x, mise 2026.9.0, and Atuin, all
from Homebrew on macOS 26.

## Executive conclusion

`gh`, `mise`, and `atuin` all write through a symlinked configuration file and
leave the link intact, so all three are safe to manage with Stow. Zed was not
verified, because its settings are rewritten by the application interface
rather than by a command that can be driven from a test. `~/.config/gh/hosts.yml`
must stay untracked regardless.

## Method

ADR 0004 established the criterion: an application whose configuration is
managed must be shown to write *through* a symlink rather than replace it, the
way Git resolves symlinks before taking its config lock. Each tool was pointed
at a scratch configuration directory containing a symlink to a file outside it,
then asked to change a setting. A surviving link plus the new value in the
target file is a pass.

Each tool has an environment variable for redirecting its configuration
directory, so no real configuration was touched.

## Results

| Tool | Redirect variable | Write command | Link preserved | Value landed in target |
| --- | --- | --- | --- | --- |
| GitHub CLI | `GH_CONFIG_DIR` | `gh config set editor vim` | yes | yes |
| mise | `MISE_GLOBAL_CONFIG_FILE` | `mise use -g jq@1.7.1` | yes | yes |
| Atuin | `ATUIN_CONFIG_DIR` | `atuin config set update_check false` | yes | yes |

```console
$ ln -s "$SCRATCH/repo/config.yml" "$SCRATCH/cfg/gh/config.yml"
$ GH_CONFIG_DIR="$SCRATCH/cfg/gh" gh config set editor vim
$ ls -l "$SCRATCH/cfg/gh/config.yml"
lrwxr-xr-x ... config.yml -> .../repo/config.yml
$ cat "$SCRATCH/repo/config.yml"
editor: vim
version: "1"
```

Note that `mise use -g` also installs the requested tool as a side effect, so
the test tool was removed again with `mise uninstall jq@1.7.1`.

## Zed was not verified

Zed rewrites `~/.config/zed/settings.json` when settings are changed in its
interface. There is no command-line equivalent to drive from a test, so the
symlink question cannot be answered the way it was for the other three. The
package is therefore left out until the behaviour is confirmed by changing a
setting in Zed and checking that the path is still a link:

```sh
ls -l ~/.config/zed/settings.json
```

This matters more for Zed than for the others, because ADR 0007 makes Zed a
declared cask and the macOS settings register it as the default handler for
twenty-one file types. Its configuration is the most conspicuous unmanaged
file left.

## `hosts.yml` holds no token on this machine, and is still excluded

ADR 0004 and the README stated that `~/.config/gh/hosts.yml` holds an
authentication token. That is not true here. GitHub CLI stores the token in the
macOS keyring, and the file contains only the protocol and user name:

```console
$ grep -c oauth_token ~/.config/gh/hosts.yml
0
$ gh auth status | grep -i keyring
  ✓ Logged in to github.com account hasansezertasan (keyring)
```

The exclusion still stands, for the accurate reason: GitHub CLI writes
`oauth_token` into `hosts.yml` when no system keyring is available, so a
machine without one would place a live token at a tracked path. The file is
gitignored so that cannot happen by accident.

## File permissions are relaxed by managing a config

Git records only `644` and `755`. Three of the candidate files are `600`:

```console
$ stat -f '%Sp %N' ~/.config/gh/config.yml ~/.config/atuin/config.toml ~/.config/mise/config.toml
-rw------- /Users/hasansezertasan/.config/gh/config.yml
-rw------- /Users/hasansezertasan/.config/atuin/config.toml
-rw-r--r-- /Users/hasansezertasan/.config/mise/config.toml
```

Linking them therefore makes the two `600` files group- and world-readable.
Neither contains a credential, so this is acceptable, but it is a real
consequence and another reason to keep credential-bearing files unmanaged.

## Atuin's configuration is almost entirely comments

`atuin/config.toml` is 403 lines, of which 8 are active, and one of those is
the only real setting (`enter_accept = true`); the rest are empty section
headers. It is tracked verbatim, as shipped, so the upstream documentation of
available options is preserved. The cost is that an upstream template change
produces a large diff for no behavioural change.
