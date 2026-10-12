# Track Generated Project Skills

## Context and Problem Statement

ADR 0002 chose to commit `skills-lock.json` while ignoring the generated
`.agents/skills/` files, to avoid duplicating upstream skill contents and to
keep diffs focused. The repository has since reversed that trade-off: the
generated tree is now tracked and marked as auto-generated, so skill updates
are reviewable in pull requests and fresh checkouts work without a restore
step. `README.md` and this decision record still described the old
lockfile-only policy, leaving contributors with contradictory guidance.

## Considered Options

* Keep ignoring generated `.agents/skills/` files (status quo ante)
* Track the generated tree and mark it `linguist-generated` via
  `.gitattributes`
* Vendor project skills in a different location outside `.agents/`

## Decision Outcome

Chosen option: "Track the generated tree and mark it `linguist-generated`".
`.agents/skills/**` is tracked with a do-not-hand-edit note in
`.gitattributes`; `skills-lock.json` remains the provenance manifest and
`npx skills experimental_install` can still regenerate the tree.

This decision supersedes
[ADR 0002](0002-lock-project-skills.md).

### Consequences

* Good, because skill content changes are visible and reviewable in pull
  requests alongside the lockfile change.
* Good, because a fresh checkout has project skills available without running
  a restore command first.
* Good, because GitHub collapses `linguist-generated` diffs, keeping reviews
  focused.
* Bad, because upstream skill updates now produce larger diffs than
  lockfile-only changes did.
* Bad, because hand edits to generated files can still be overwritten by the
  next install; the `.gitattributes` note is advisory, not enforced.

## Related Research

* [Tracking generated project skills](../research/0016-tracking-generated-project-skills.md)
