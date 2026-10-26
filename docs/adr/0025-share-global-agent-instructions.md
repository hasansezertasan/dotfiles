# Share Global Agent Instructions Across Coding Agents

## Context and Problem Statement

`claude/.claude/CLAUDE.md` holds the global instructions, but it described
itself as guidance for Claude Code only, and only Claude Code and opencode
(through a fallback) read it. `~/.codex/AGENTS.md` was a hand-made absolute
symlink outside Stow. Separately, skills that babysit pull requests or run
review rounds reply to and resolve review threads without asking, which
contradicts the approval gate in ADR 0022 and forces the user to type "reply and
resolve" by hand.

## Considered Options

* Reinstate a `codex` Stow package that links only `AGENTS.md`
* Keep the hand-made Codex symlink
* Rename the file to `AGENTS.md` and link it everywhere (draft PR #38)
* Fork or edit each skill that resolves threads so it asks first
* State the review-thread rule once in the global instructions

## Decision Outcome

Chosen options: "Reinstate a `codex` Stow package that links only `AGENTS.md`"
and "State the review-thread rule once in the global instructions".

The `codex` package contains `.codex/AGENTS.md`, a relative symlink to the
`claude` package's `CLAUDE.md`, and is added to `PACKAGES` in `link.sh` and the
expected links in `link_test.sh`. The file is renamed in neither direction:
`CLAUDE.md` stays the source, so the existing `claude` link and every reference
to it keep working. The intro now addresses coding agents generally.

This does not reverse ADR 0017. That record removed the package because Orca
rewrites `hooks.json` with a machine-specific path; `AGENTS.md` is not written
by Orca, and `hooks.json` stays unmanaged.

A "Review threads" convention requires an agent given a review thread or
review link, or finding one while babysitting, to draft a reply and ask with
`AskUserQuestion` to reply and resolve. It states that it overrides any skill step that replies or resolves on
its own, and that a delegated watcher only reports. Editing or forking the skills
was rejected because some are generated content that an update can overwrite,
and the user preferred one global statement.

opencode needs no link because it falls back to `~/.claude/CLAUDE.md`. pi
(`~/.pi/agent/AGENTS.md`) and Antigravity are left unlinked: pi is a follow-up,
and Antigravity's global `AGENTS.md` support is unverified.

### Consequences

* Good, because Claude Code, Codex and opencode read one set of instructions,
  and the Codex link is reproducible from the repository.
* Good, because the reply-and-resolve prompt no longer depends on the user
  remembering to ask.
* Bad, because a prose override is weaker than editing the skills: a skill's
  explicit step can still win, and a stop condition such as "no unresolved
  review threads remain" pushes toward silent resolution.
* Bad, because the Codex link is a two-hop chain whose target must keep its
  path; draft PR #38, which renames `CLAUDE.md`, would break it.
* Bad, because an existing `~/.codex/AGENTS.md` link is a Stow conflict and
  must be removed once before `./link.sh install`.

## Related Research

* [Global agent instruction discovery](../research/0020-global-agent-instruction-discovery.md)
* [Global Claude operating policies](../research/0019-global-claude-policies.md)
