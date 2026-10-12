# Global Claude operating policies

Research snapshot: 2026-10-12.

## Executive conclusion

`claude/.claude/CLAUDE.md` is the Stow-managed file that becomes the global
`~/.claude/CLAUDE.md`, so every rule in it applies to agent sessions across
projects. Three additions since the last recorded decision needed a home:
an explicit approval gate for issue/PR actions, pinned subagent models for
reading-heavy work, and a git-repository investigation policy. All three are
documented as intentional operating policy in ADR 0022.

## Inventory

| Addition | Rule |
| --- | --- |
| Approval gate | Never comment on, file, or open an issue/PR without explicit approval for that action; draft first, ask via AskUserQuestion |
| Subagent models | Research and other reading-heavy subagents run on `sonnet` unless the skill names a model |
| Repository investigation | Clone a provided repo URL into a fresh temp dir and use local tools (`rg`, file reads); web/`gh` only for non-file needs or on failure |

No credentials or machine-specific content are involved; the file stays
portable as before.
