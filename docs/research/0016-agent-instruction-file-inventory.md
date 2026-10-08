# Agent Instruction File Inventory

## Scope

Inspect the tracked instruction files and their references before consolidating
on `AGENTS.md`.

## Findings

* The repository root already contains `AGENTS.md` with repository-specific rules.
* `claude/.claude/CLAUDE.md` is the only other tracked instruction file.
  Its directory has no `AGENTS.md`, so renaming it preserves the global rules.
* No `GEMINI.md` is tracked.
* `link_test.sh` expects the global instruction symlink under its old filename.
* The managed PR skill uses the old filename in an example and a policy reference.
* ADR 0014 mentions the old path as a historical record of its original decision.
* Stow discovers package contents, so the new filename needs no package-list change.
  A symlink created at the old path by an earlier install needs explicit removal;
  the README documents that upgrade step.

## Basis

Local inspection with `git ls-files`, reference search, and reads of the instruction
file, PR skill, `link.sh`, and `link_test.sh`.
The requested switch assumes the user's Claude Code installation supports
`AGENTS.md`; runtime discovery was not tested here.
