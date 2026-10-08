# Consolidate Instructions on AGENTS.md

## Status

Accepted

## Context and Problem Statement

The user no longer uses Gemini and wants instruction files standardized on
`AGENTS.md`, including Claude Code's global instructions.
The repository already has a root `AGENTS.md`, while the global instructions
are managed under `claude/.claude/CLAUDE.md`.
Claude Code's `AGENTS.md` discovery is project-scoped; user-level Markdown
rules under `~/.claude/rules/` load for every project.

## Considered Options

* Keep tool-specific instruction filenames.
* Standardize on `AGENTS.md`, retaining existing files and renaming an alternate
  instruction file wherever no `AGENTS.md` exists, placing global instructions
  in Claude Code's user-level rules directory.
* Keep a `CLAUDE.md` import entry point alongside the global `AGENTS.md`.

## Decision Outcome

Chosen option: "Standardize on AGENTS.md".
Rename `claude/.claude/CLAUDE.md` to `claude/.claude/rules/AGENTS.md`, preserving its
rules and making the project-override exemption filename-neutral.
The rule has no `paths` frontmatter, so it loads for every project.
This avoids the user-level discovery regression identified during PR review
while fulfilling the request to remove `CLAUDE.md`.
Update the link test and managed PR skill to use the new filename.
There is no tracked `GEMINI.md` to remove.

### Consequences

* Good, because global and repository instruction files share one filename.
* Good, because the existing global rules are preserved.
* Existing installations must remove the old repository-owned instruction symlink
  when restowing; the README documents this migration.
* The historical path in ADR 0014 remains a record of the earlier layout.

## Related Research

* [Agent instruction file inventory](../research/0016-agent-instruction-file-inventory.md)
