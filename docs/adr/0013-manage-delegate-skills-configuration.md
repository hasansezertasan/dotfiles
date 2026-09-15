# Manage delegate-skills configuration

## Context and Problem Statement

The delegate-fleet system uses `~/.config/delegate-skills/config.json` for lane
configuration. This file defines which implementer and model to use for
different task lanes (feature, tests, fast, complex).

## Considered Options

* Do not manage — leave as local file
* Manage the config file via stow

## Decision Outcome

Chosen option: "Manage the config file via stow", because the file contains only
portable lane preferences with no credentials or machine-specific paths.

The `delegate-skills` package links `~/.config/delegate-skills/config.json`.
The file is read-only configuration — no CLI writes to it programmatically,
so symlink write-through is not a concern.

### Consequences

* Good, because lane configuration is versioned and portable across machines
* Good, because the config directory has no sensitive siblings requiring gitignore allowlists
* Neutral, because the file is small and rarely changes

## Related Research

* [delegate-skills Configuration Investigation](../research/0011-delegate-skills-stow-package.md)
