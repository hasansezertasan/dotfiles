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

## Review Follow-up: Global Instruction Discovery

Both PR reviewers identified that renaming the global file directly to
`~/.claude/AGENTS.md` would lose automatic user-level loading.
The [official memory documentation](https://code.claude.com/docs/en/memory#agents-md),
checked on 2026-10-08, confirms that `AGENTS.md` discovery covers project paths
and that `~/.claude/CLAUDE.md` is the user-level instruction entry point.

The same documentation's
[user-level rules section](https://code.claude.com/docs/en/memory#user-level-rules)
states that Markdown rules in `~/.claude/rules/` apply to every project.
Rules without `paths` frontmatter load unconditionally.
Therefore the global file belongs at `claude/.claude/rules/AGENTS.md`, keeping
the requested filename and automatic user-level loading without a `CLAUDE.md`.
The existing Stow behavioural suite checks the installed rule symlink and
that its shared directory is a real directory.
