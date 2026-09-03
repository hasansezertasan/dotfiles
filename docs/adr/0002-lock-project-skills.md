# Lock Project Skills without Vendoring Them

## Context and Problem Statement

This repository relies on agent skills for research and architecture decision
records. Contributors need a reproducible declaration of those dependencies,
but generated skill files duplicate their upstream sources and create noisy
repository updates.

## Considered Options

* Commit `skills-lock.json` and ignore generated `.agents/skills/` files
* Commit both the lockfile and generated skill files
* Keep skills installed globally without a project dependency declaration

## Decision Outcome

Chosen option: "Commit `skills-lock.json` and ignore generated
`.agents/skills/` files", because the lockfile records each source, path, and
content hash while `npx skills experimental_install` can restore the generated
files when needed.

### Consequences

* Good, because skill dependencies and integrity hashes are versioned.
* Good, because upstream skill contents are not duplicated in this repository.
* Good, because updates produce focused lockfile diffs.
* Bad, because a fresh checkout requires a restore command before project skills
  are available locally.
