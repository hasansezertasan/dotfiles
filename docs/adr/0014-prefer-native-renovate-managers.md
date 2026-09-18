# Prefer Native Renovate Managers Over Custom Regex Managers

## Context and Problem Statement

Renovate can read a version either through a native manager, which understands a
known manifest format, or through a `customManager`, which applies a
hand-written regex to an arbitrary file. A regex manager is the only option when
a version is pinned in a file no native manager parses, and it is tempting to
reach for one because it works immediately. It then covers only the stanzas
someone remembered to write a pattern for, so dependencies added later are
silently left unmanaged and the omission surfaces as a missed update rather than
as a failure. The repository's global Claude instructions had no rule for this
choice.

## Considered Options

* Prefer a native manager, and move the pinned version into a manifest one
  already covers
* Allow a `customManager` whenever it is the shortest path to a covered version
* Say nothing and decide case by case

## Decision Outcome

Chosen option: "Prefer a native manager, and move the pinned version into a
manifest one already covers". The rule is recorded as a `Renovate` section in
`claude/.claude/CLAUDE.md`, alongside the existing branch, commit, and PR title
conventions, so it applies to every repository worked on from this machine.

When a version is pinned somewhere Renovate cannot read, the fix is to relocate
it into a manifest a native manager already handles — `package.json`,
`mise.toml`, and similar — rather than to write a regex that scans the ad-hoc
file. A regex manager that keeps two hand-written copies of a version in sync
identifies the duplication as the real defect. Where a regex manager is
genuinely unavoidable, its `description` must state why no native manager fits,
so the exception carries its own justification.

The claim about native coverage is scoped to supported entries: a native manager
extracts the dependency locations and formats its module documents, not every
field a manifest may contain.

### Consequences

* Good, because new dependencies in a covered manifest are picked up without
  anyone extending a pattern.
* Good, because each surviving `customManager` explains itself at the point of
  definition.
* Good, because duplicated version pins are treated as a defect instead of being
  papered over by a second regex.
* Bad, because relocating a pinned version into a manifest is a larger change
  than adding a regex, and may not be possible when the consuming tool requires
  the ad-hoc file.
* Bad, because "supported entry" still requires reading the relevant Renovate
  manager documentation to confirm a field is covered.
