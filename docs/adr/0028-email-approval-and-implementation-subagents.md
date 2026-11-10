# Gate Emails on Approval and Bound Implementation Subagents

## Context and Problem Statement

`claude/.claude/CLAUDE.md` is Stow-managed into the global
`~/.claude/CLAUDE.md`, so its rules govern agent sessions across all
projects. Two gaps remained after
[ADR 0022](0022-global-claude-policies.md):

* Slack messages need the user's approval before they are sent, but emails
  do not, even though an email is just as outward-facing and cannot be
  recalled once delivered. A Gmail connector makes sending one a single
  tool call.
* Only reading-heavy subagents have a pinned model. Implementation skills
  (implementers and mergers) can fan out without limit on the session
  model, and each subagent re-reads its whole context on every call.

## Considered Options

* Add an email approval rule and an implementation-subagent rule (chosen)
* Fold emails into the Slack section
* Leave both to each skill's own defaults

## Decision Outcome

Chosen option: "Add an email approval rule and an implementation-subagent
rule".

* **Email approval.** Sending, replying to, forwarding, and scheduling an
  email need the user's approval of that specific email. Draft the text,
  show it, and prefer a connector draft when the user did not ask to send.
  The Slack ELI5 and Simplified Technical English style rule does not apply
  to emails. That is why emails get their own section instead of being
  folded into the Slack one.
* **Implementation subagents.** These run on `model: sonnet` unless the
  skill or ticket names a model, and at most three run in parallel,
  whatever the skill says. The next one starts when one finishes, and each
  gets context pointers (spec, ticket, notes) instead of copies.

### Consequences

* Good, because no email leaves the account without a human seeing it.
* Good, because implementation fan-out cost is bounded and predictable.
* Bad, because every email adds an approval round-trip.
* Bad, because capping parallelism at three can make large specs take
  longer in wall-clock time.

## Related Research

* [Global Claude operating policies](../research/0019-global-claude-policies.md)
