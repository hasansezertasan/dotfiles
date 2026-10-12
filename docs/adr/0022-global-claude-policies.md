# Record Global Claude Operating Policies

## Context and Problem Statement

`claude/.claude/CLAUDE.md` is Stow-managed into the global
`~/.claude/CLAUDE.md`, so its rules govern agent sessions across all
projects. Three policies were added to it without a decision record: an
approval gate for issue/PR actions, pinned subagent models for reading-heavy
work, and a git-repository investigation policy. Undocumented, they are
indistinguishable from unrelated local configuration that slipped into an
adjacent change.

## Considered Options

* Record the three policies as intentional operating constraints (chosen)
* Revert them out of this repository

## Decision Outcome

Chosen option: "Record the three policies as intentional operating
constraints".

* **Approval gate.** Never comment on an issue or PR, file an issue, or open
  a PR without the user's explicit approval for that specific action. Draft
  the text, show it, and ask for approval first. This keeps irreversible,
  public-facing actions under human control no matter which agent session
  proposes them.
* **Subagent models.** Research and other reading-heavy subagents run on
  `model: sonnet` unless the skill names a model. Search and fact-finding do
  not need the session model, so the pin saves cost without hurting quality.
* **Repository investigation.** A provided Git URL is cloned into a fresh
  temporary directory and investigated with local tools; web search, GitHub
  pages, and `gh` are reserved for information outside the files (issues,
  PRs, metadata) or for clone failures. Local evidence beats secondary
  write-ups, and the rule stops silent fallbacks to the web when cloning
  fails.

### Consequences

* Good, because safety-critical (public actions) and cost-critical (model
  choice) defaults are explicit and reviewable.
* Good, because investigation failures surface as blockers instead of
  silently degrading into web searches.
* Bad, because the approval gate adds a round-trip to every issue/PR action,
  including ones the user would have rubber-stamped.

## Related Research

* [Global Claude operating policies](../research/0019-global-claude-policies.md)
