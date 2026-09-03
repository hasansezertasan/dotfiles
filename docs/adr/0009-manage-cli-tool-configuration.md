# Manage Command-line Tool Configuration

## Context and Problem Statement

ADR 0004 deferred `~/.config/gh`, `~/.config/zed`, `~/.config/atuin`, and
`~/.config/mise` because each is written by its own application, and managing a
file an application replaces would silently detach the Stow link. It set the
criterion but left the check undone. ADR 0007 then made Zed a declared cask and
kept the macOS settings that register it as the default handler for twenty-one
file types, so the repository now installs and configures applications whose
own configuration it does not version.

## Considered Options

* Manage the tools whose write behaviour has been verified, and leave the rest
* Manage all four candidates and accept the unverified ones
* Keep all four unmanaged until Zed can also be verified
* Manage only `mise`, whose configuration is smallest

## Decision Outcome

Chosen option: "Manage the tools whose write behaviour has been verified, and
leave the rest". `gh`, `mise`, and `atuin` were each pointed at a scratch
configuration directory containing a symlink and asked to change a setting.
All three wrote through the link and left it intact, so `gh config set`,
`mise use -g`, and `atuin config set` continue to work and their changes appear
as repository changes, exactly as with `git config --global`.

Zed is left unmanaged. Its settings are rewritten by the application interface
and there is no command to drive from a test, so the criterion cannot be
satisfied yet. The README records the one-line check to run before adding it.

`~/.config/gh/hosts.yml` is excluded and gitignored. The reason recorded in
ADR 0004 was inaccurate: on this machine GitHub CLI keeps the token in the
system keyring and the file holds only the protocol and user name. The
exclusion stands for the correct reason, which is that GitHub CLI writes
`oauth_token` into that file when no keyring is available, so the path must
never be tracked.

Git records only `644` and `755`, so linking the `600` files relaxes their
permissions. Neither holds a credential, which is what makes that acceptable.

`link_test.sh` was extended with the three new links and directories, and each
new package was mutation-checked by removing it from `PACKAGES` and confirming
the test fails.

### Consequences

* Good, because the configuration of the tools the shell actually integrates
  with is now versioned and restored by `./link.sh install`.
* Good, because each tool's own command remains the way to change its settings.
* Good, because the credential-bearing path is both unmanaged and gitignored,
  so it cannot be committed by accident.
* Good, because the write behaviour behind the decision is verified rather than
  assumed, and the test fails if a package is dropped.
* Bad, because linking a `600` configuration file makes it world-readable.
* Bad, because `atuin/config.toml` is tracked verbatim at 403 lines to express
  one setting, so upstream template changes produce large, meaningless diffs.
* Bad, because Zed remains unmanaged while being installed and registered as a
  default handler, which is the most visible inconsistency left.
* Bad, because each managed path needs a one-time manual move before the first
  install.

## Related Research

* [Symlink safety of the candidate application configurations](../research/0007-symlink-safety-of-cli-tool-config.md)
