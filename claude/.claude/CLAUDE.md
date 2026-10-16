<!-- Prose here uses semantic line breaks: break at clause and sentence
     boundaries, never at a fixed column, so edits don't reflow neighbours. -->

# Global Instructions

This file provides guidance to Claude Code (claude.ai/code)
when working with code in all repositories.

## Critical

Never add claude.ai/code as a collaborator (or "Co-Authored-By") to any repository.
This is a critical security risk and must be avoided at all costs.
Also, never add claude.ai/code to any commit history or codebase,
as this could lead to security vulnerabilities and potential breaches.

Never use "🤖 Generated with Claude Code" or any statement, trailer, or footer
that hints the work was done by an AI agent
— in commit messages, PR titles/descriptions, code comments, or documentation —
unless explicitly told to do so.

Never comment on an issue or PR, file an issue, or open a PR
without the user's explicit approval for that specific action.
Draft the text, show it,
and ask for approval with the AskUserQuestion tool before posting.

## Conventions

Apply these in every project
unless the project's own `CLAUDE.md` overrides them.

### Branch names

[Conventional Branch](https://conventional-branch.github.io/):
`<type>/<description>`, lowercase and hyphen-separated.
Types: `feature`, `bugfix`, `hotfix`, `release`, `chore`.
Include the ticket when one exists: `feature/issue-123-add-login`.

### Commit messages

[Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):
`<type>[(scope)][!]: <description>`, with an optional body and footers.
`feat` and `fix` carry their spec meanings;
`!` or a `BREAKING CHANGE:` footer marks a breaking change.

### PR titles

Same format as the commit message,
so the [Conventional Pull Request](https://github.com/marketplace/actions/conventional-pull-request)
action passes.

### Renovate

Prefer a native manager over a `customManager`.
When a version is pinned somewhere Renovate cannot read,
move it into a manifest a native manager already covers
(`package.json`, `mise.toml`, …) rather than writing regex to scan the ad-hoc file.
Native managers cover every supported entry in a manifest automatically;
a regex covers only the stanzas someone remembered to write,
so it silently stops covering new dependencies.

A regex manager that has to keep two hand-written copies of a version in sync
is a sign the duplication is the real bug.
When one is genuinely unavoidable,
its `description` must say why no native manager fits.

### Subagent models

Research and other reading-heavy subagents
(e.g. `mattpocock-skills:research`, Wayfinder research)
run on `model: sonnet` unless the skill names a model.
Their work is search and fact-finding,
which doesn't need the session model.

### Context hygiene

Every tool call re-reads the whole session context, so a session that has grown large
makes each later step expensive and can use the available allowance sooner
within a plan's fixed five-hour reset period.
At a phase boundary, if the session already holds a lot
(many large file reads, subagent reports or CI logs, or well over 100 tool calls),
ask with `AskUserQuestion` whether to start fresh
before beginning the next phase.
Offer **Fresh session** (write a short handoff note first: goal, branch, decisions, what remains),
**Continue**, or stop and ask the user to type `/compact` themselves.
A `/compact` choice inside `AskUserQuestion` is only a tool result, not a command invocation.
Never clear or compact unasked.

Phase boundaries, for example:

- investigation done, before implementing
- implementation green, before review
- review fixed, before opening the PR
- each CI/review round while babysitting a PR
- a plan or spec finished, before executing it

Do not answer "Keep going" or "proceed" with a new fan-out of subagents in a session that is already large;
raise the same question first.

### Review effort

Run code reviews (`/code-review`, `code-review:code-review`, review subagents) at `high` or below.
Never use `max` or `xhigh` without asking first with `AskUserQuestion`,
and name the level explicitly instead of letting a skill reuse the last one.
`max` fans out into ten or more finder agents plus verifiers,
each re-reading hundreds of thousands of tokens of context on every call,
and in measured sessions it was about 90% of the tokens.
When asked for several reviews of one diff, run one reviewer unless the change is risky.

## Investigating Git repositories

- When the user provides a Git repository URL, always clone the repository into a fresh temporary directory and investigate its local files.
- Use local tools such as `rg`, `rg --files`, and direct file reads for repository file discovery and investigation. Do not use web searches, GitHub web pages, or `gh` merely to discover or read repository files.
- If cloning fails because of access, authentication, or network issues, report the blocker rather than silently switching to web search or `gh` for file discovery.
- Use web browsing or `gh` only when the task needs information outside the cloned files, such as externaldocumentation, issues, pull requests, or repository metadata, or when the user explicitly requests it.
