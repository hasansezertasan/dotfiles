# Global agent instruction discovery

Research snapshot: 2026-10-26.

## Executive conclusion

`claude/.claude/CLAUDE.md` is the single hand-edited source of global agent
instructions. Codex needs its own link to read it, opencode already reads it
through a documented fallback, pi needs its own link, and Antigravity's global
`AGENTS.md` support is unverified. Separately, two vendored skills tell the
agent to reply to and resolve review threads without asking, which conflicts
with the approval gate recorded in ADR 0022.

## Where each agent reads global instructions

| Agent | Global path | Reads `~/.claude/CLAUDE.md`? | Status |
| --- | --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` | Native | Linked by the `claude` package |
| Codex | `~/.codex/AGENTS.md` | No | Was a hand-made absolute link; now the `codex` package |
| opencode | `~/.config/opencode/AGENTS.md` | Yes, only when its own file is missing | No link needed; `OPENCODE_DISABLE_CLAUDE_CODE=1` disables the fallback |
| pi | `~/.pi/agent/AGENTS.md` | No | Not linked yet |
| Antigravity | `~/.gemini/GEMINI.md`, possibly `~/.gemini/AGENTS.md` | Unknown | Third-party sources only; not linked |

Antigravity sources agree on `~/.gemini/GEMINI.md`. A global
`~/.gemini/AGENTS.md` (reportedly since v1.20.3) and the rule that `GEMINI.md`
wins when both exist appear only in third-party guides. The same guides warn
that Antigravity and Gemini CLI share `~/.gemini/GEMINI.md`.

Sources:

* <https://opencode.ai/docs/rules/>
* <https://pi.dev/docs/latest/configuration>
* <https://thepromptshelf.dev/blog/google-antigravity-agents-md-rules-guide-2026>
* <https://docs.coingecko.com/docs/ai-agent-hub/antigravity.md>

## Stow behaviour for the Codex link

Stow cannot link into another package, so the `codex` package holds
`.codex/AGENTS.md` as a relative symlink to `../../claude/.claude/CLAUDE.md`.
The result is `~/.codex/AGENTS.md` -> `codex/.codex/AGENTS.md` ->
`claude/.claude/CLAUDE.md`, with no absolute path in the repository. `link_test.sh`
follows the chain and checks that it resolves inside the repository. A hand-made
`~/.codex/AGENTS.md` link conflicts and must be removed once.

ADR 0017 removed the earlier `codex` package because Orca rewrites
`~/.codex/hooks.json`. Orca does not write `AGENTS.md`, so that objection does
not apply to this file.

## Review-thread handling

Earlier sessions show the same manual request repeatedly: after the agent fixed
a review finding, the user typed "reply and resolve" (or a variant) in at least
six sessions, and asked for a comment plus resolved threads in another.

Skills that watch a pull request or run review rounds can include steps that
reply to or resolve review threads without asking. That contradicts the
approval gate in ADR 0022 and leaves the user to request the reply by hand.

Some of those skills are generated content that an update can overwrite, and
the user chose not to edit or fork them. Stating the rule once in the global
instructions, as an override of any such step, applies to every agent and every
skill without touching either.
