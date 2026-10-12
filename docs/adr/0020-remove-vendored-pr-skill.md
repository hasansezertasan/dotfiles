# Remove the Vendored PR Skill

## Context and Problem Statement

This repository vendored a `pr` skill in the `claude` Stow package
(`claude/.claude/skills/pr/`: `SKILL.md`, `scripts/preflight.sh`,
`scripts/test_preflight.sh`) that front-loaded branch naming, history
hygiene, and PR handoff decisions. ADR 0012 and research 0010 describe that
local skill as the companion to the `check-pr-title.yml` and
`check-branch-name.yml` CI gates. The skill is now maintained outside this
repository and consumed from the global skills installation, so the vendored
copy was deleted — leaving the ADR, the old machines' symlinks, and the
workflow comment pointing at something that no longer exists.

## Considered Options

* Keep vendoring the skill in the `claude` package
* Delete the vendored copy and clean up after it (chosen)
* Keep the copy but stop linking it

## Decision Outcome

Chosen option: "Delete the vendored copy and clean up after it".

* `claude/.claude/skills/pr/` is removed from the package.
* `link.sh` `install`, `restow`, and `uninstall` drop the three stale
  `~/.claude/skills/pr/...` links when — and only when — each link still
  points at its former repository target, then remove directories left
  empty. This mirrors the ADR 0017 Codex-hook migration; no content recovery
  is needed because skill files are read-only.
* `check-branch-name.yml` no longer names the skill; the branch policy is
  stated inline in the workflow.
* ADR 0012 keeps its history but carries a note pointing here; research 0010
  stays untouched as a dated snapshot of the pre-removal state.

This decision supersedes the local-skill portion of
[ADR 0012](0012-adopt-pr-title-and-branch-name-ci-gates.md).

### Consequences

* Good, because one canonical skill source replaces a vendored copy that
  could drift from it.
* Good, because old machines do not keep dangling skill links that confuse
  agents looking for PR guidance.
* Good, because the ownership check never touches links owned by something
  else, and `rmdir` only removes empty directories.
* Bad, because a fresh checkout of this repository alone no longer provides
  the PR workflow; contributors get it from the global skills installation.

## Related Research

* [Removing the vendored pr skill](../research/0017-pr-skill-removal.md)
