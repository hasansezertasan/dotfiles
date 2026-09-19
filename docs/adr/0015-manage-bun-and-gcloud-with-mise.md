# Manage Bun and the Google Cloud CLI with mise

## Context and Problem Statement

Bun and the Google Cloud CLI are both in daily use on this machine and neither
was restored by the dotfiles repository. Every other runtime-style tool already
reaches the machine one of two ways: as a Homebrew formula or cask declared in
the `Brewfile`, or as a pinned entry in the global mise configuration, which
ADR 0009 made a Stow-managed file after confirming that `mise use -g` writes
through the symlink. Until now that mise configuration pinned only `uv`, so the
two tools were installed by hand and their versions differed from machine to
machine.

## Considered Options

* Pin both tools in the global mise configuration
* Declare both in the `Brewfile`
* Leave both to manual installation

## Decision Outcome

Chosen option: "Pin both tools in the global mise configuration". `bun` is
pinned at `1.4.0` and `gcloud` at `581.0.0` in
`mise/.config/mise/config.toml`, next to the existing `uv` pin.

The `Brewfile` remains the place for applications and for tools with a single
system-wide version, including mise itself. mise remains the place for tools
whose version is pinned deliberately and may need to be changed or rolled back
without touching Homebrew. Bun and the Google Cloud CLI both fall on the mise
side: each releases frequently, and an exact pin makes the version an explicit,
reviewable repository change rather than whatever the last `brew upgrade`
produced.

Because the mise configuration is already a Stow-managed file, `mise use -g`
continues to be the way to change a pin, and the change appears directly as a
repository diff.

Only the CLI binaries are managed here. The Google Cloud CLI's state under
`~/.config/gcloud` stays unmanaged, because it is a credential store rather
than portable configuration.

### Consequences

* Good, because bootstrap now restores both tools at a known version.
* Good, because the pinned versions are explicit and reviewable, and a rollback
  is a one-line change.
* Good, because the configuration file stays the single list of
  deliberately pinned tool versions.
* Bad, because mise's builds of these tools are not Homebrew's, so any
  packaging difference is inherited from mise's backend.
* Bad, because exact pins do not move on their own; each upgrade is a manual
  edit until this repository adopts an automated updater.

## Related Research

* [Symlink safety of the candidate application configurations](../research/0007-symlink-safety-of-cli-tool-config.md)
* [Stow candidate scan, September 2026](../research/0012-stow-candidate-scan-2026-09.md)
