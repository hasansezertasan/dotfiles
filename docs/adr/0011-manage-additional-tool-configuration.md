# Manage Additional Tool Configuration with Narrow Stow Packages

## Context and Problem Statement

The home directory contains portable SSH, olink, OpenCode, Zed, and Codex
configuration that is not restored by the dotfiles repository. Each location
also contains, or may later contain, credentials and mutable application state.
The useful files need to be versioned without turning whole application
directories into repository content.

## Considered Options

* Manage narrow, explicit packages containing only portable files
* Import each candidate directory wholesale
* Manage all files except those currently known to contain credentials
* Leave all five tools unmanaged

## Decision Outcome

Chosen option: "Manage narrow, explicit packages containing only portable
files". Add `ssh`, `olink`, `opencode`, `zed`, and `codex` to the fixed package
list used by `link.sh`.

SSH manages only `.ssh/config`, protected by an ignore allowlist that rejects
all other files under the package. olink manages its pins file. OpenCode manages
the canonical global config and dependency manifest while relying on OpenCode's
documented automatic discovery for application-installed plugins. Zed manages
only its settings file.

Codex manages only `hooks.json`, with its absolute home path replaced by
`$HOME`. `config.toml` is intentionally not managed because durable settings
and generated machine state occupy the same file. The Codex ignore allowlist
prevents other `.codex` content from being staged accidentally.

The packages continue to use Stow's `--no-folding` option. Their shared parent
directories remain real directories where each application can maintain its
untracked state. The behavioural test asserts every new link and shared
directory so deleting a package from the fixed list fails the test.

### Consequences

* Good, because five more tools restore useful configuration during bootstrap.
* Good, because SSH keys and Codex credentials, sessions, and databases are
  protected by package-level ignore allowlists.
* Good, because OpenCode no longer needs a managed absolute plugin path.
* Good, because the Codex hook works for any home directory.
* Bad, because Codex's main preferences remain unmanaged with its generated
  state.
* Bad, because Zed, olink, or an integration installer may replace a symlink;
  their write behaviour has not been reproduced safely.
* Bad, because files previously mode `600` are checked out as `644` by Git.

## Related Research

* [Boundaries for additional Stow packages](../research/0009-additional-stow-package-boundaries.md)
* [Symlink safety of the candidate application configurations](../research/0007-symlink-safety-of-cli-tool-config.md)
