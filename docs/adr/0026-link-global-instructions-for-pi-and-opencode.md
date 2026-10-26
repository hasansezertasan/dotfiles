# Link Global Instructions for pi and opencode

## Context and Problem Statement

ADR 0025 linked the global instructions into Codex and left two agents open.
pi reads `~/.pi/agent/AGENTS.md` and does not read `~/.claude/CLAUDE.md`, so it
received nothing. opencode reads `~/.config/opencode/AGENTS.md` and falls back
to `~/.claude/CLAUDE.md` when that file is missing, but whether opencode V2 keeps
that fallback is unverified.

## Considered Options

* Add a `pi` package and an `AGENTS.md` link in the `opencode` package
* Add the `pi` package only and rely on the opencode fallback
* Leave both agents unlinked

## Decision Outcome

Chosen option: "Add a `pi` package and an `AGENTS.md` link in the `opencode`
package". Each is a relative symlink to the `claude` package's `CLAUDE.md`,
following the `codex` package from ADR 0025.

The `pi` package manages only `.pi/agent/AGENTS.md`. `~/.pi/agent` also holds
`auth.json`, `models-store.json`, sessions, extensions and `settings.json`; none
are tracked, and because the package contains no other file, no ignore rule is
needed. The `opencode` link makes the setup independent of the fallback, so it
holds whichever way V2 behaves. opencode prefers its own `AGENTS.md`, so the
fallback is never read once the link exists.

Antigravity stays unlinked: its global `AGENTS.md` support rests on third-party
sources only.

### Consequences

* Good, because pi and opencode read the same global instructions as Claude Code
  and Codex, independent of any fallback.
* Good, because the `opencode` package keeps tracking only files it owns.
* Bad, because every agent link now depends on the path
  `claude/.claude/CLAUDE.md`; renaming it, as draft PR #38 proposes, breaks four
  links at once.
* Bad, because a hand-made link at either path is a Stow conflict and must be
  removed once before `./link.sh install`.

## Related Research

* [Global agent instruction discovery](../research/0020-global-agent-instruction-discovery.md)
