# Use MADR for Decision Records

## Context and Problem Statement

Technical decisions need to remain discoverable after their originating
conversation or pull request. Unstructured decision notes do not establish
which context, alternatives, and consequences must be retained.

## Considered Options

* Record decisions using Markdown Architectural Decision Records (MADR)
* Keep unstructured notes in a general decisions directory
* Keep decisions only in research notes and pull requests

## Decision Outcome

Chosen option: "Record decisions using MADR", because it provides a concise,
repeatable structure while keeping decisions versioned beside the configuration
they govern. Records live in `docs/adr/` and use sequential four-digit prefixes.

### Consequences

* Good, because each decision preserves its context, alternatives, outcome, and
  consequences.
* Good, because future contributors have one predictable decision log.
* Bad, because meaningful decisions require an additional document to maintain.
