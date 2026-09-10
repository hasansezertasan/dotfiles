# Manage the Global Skills Lock with a Narrow Stow Package

## Context and Problem Statement

The Skills CLI records globally installed skills in
`~/.agents/.skill-lock.json`, while its adjacent `~/.agents/skills/` directory
holds generated installed content. The portable manifest should be restored on
a new machine without committing generated skill trees.

## Considered Options

* Manage only the global skill-lock manifest
* Manage the entire `~/.agents` directory
* Leave the Skills CLI state unmanaged

## Decision Outcome

Chosen option: "Manage only the global skill-lock manifest", because it
preserves portable skill provenance while excluding generated content.

Add the `agents` package to the fixed `link.sh` package list. It links only
`~/.agents/.skill-lock.json`; `.agents/skills/` remains ignored and local. The
Skills CLI was verified to write through the manifest symlink, so global skill
operations update the tracked copy rather than replacing the link.

### Consequences

* Good, because a fresh machine can restore the same global skill selection.
* Good, because generated installed skill directories are not versioned.
* Bad, because skill content must still be installed or restored locally.
* Bad, because using `XDG_STATE_HOME` changes the CLI's manifest location.

## Related Research

* [Stow boundary for the global Skills CLI manifest](../research/0010-agents-skill-lock-stow-package.md)
