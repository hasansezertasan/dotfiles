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
