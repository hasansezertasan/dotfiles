# Pin Copier in the mise Toolset

## Context and Problem Statement

The global mise configuration pins exact versions of everyday tools (ADR
0015: `bun`, `gcloud`, `uv`). Copier — used to scaffold and update projects
from shared templates such as `hasansezertasan/copier-pyproject`, the source
of this repository's PR-title and branch-name gates — was installed by hand,
so new machines lacked it after bootstrap until someone noticed.

## Considered Options

* Pin `copier` in the global mise configuration (chosen)
* Declare it in the `Brewfile`
* Leave it to manual installation

## Decision Outcome

Chosen option: "Pin `copier` in the global mise configuration".
`copier = "9.18.2"` sits alongside the existing pins in
`mise/.config/mise/config.toml`, so bootstrap restores it at a known version
and upgrades arrive as explicit, reviewable repository changes (now via
Renovate, per ADR 0018). Like the other pins, it falls on the mise side
rather than the Brewfile side: the version is deliberate and may need to
change or roll back independently of Homebrew.

### Consequences

* Good, because new installs get Copier at a known version with no manual
  step.
* Good, because the pin is explicit and covered by the same update
  automation as the other tools.
* Bad, because it adds one more exact pin that goes stale without its
  updater.

## Related Decisions

* [ADR 0015](0015-manage-bun-and-gcloud-with-mise.md) (mise as the place for
  deliberately pinned tools)
* [ADR 0018](0018-adopt-renovate-with-the-shared-preset.md) (automated pin
  updates)
