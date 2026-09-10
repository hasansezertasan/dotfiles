# Adopt PR Title and Branch Name CI Gates

## Context and Problem Statement

This repository requires Conventional Commits for commit messages and pull
request titles, as well as Conventional Branch naming (`<type>/<description>`).
While local pre-flight checks (`claude/.claude/skills/pr/`) assist contributors
before pushing, the repository lacked server-side GitHub Actions checks to
enforce these standards on incoming pull requests. Without automated CI gates,
malformed PR titles and branch names must be caught manually during review.

## Considered Options

* Adopt `check-pr-title.yml` and `check-branch-name.yml` from `hasansezertasan/copier-pyproject`
* Rely only on manual review and local pre-flight scripts
* Implement a custom consolidated monolithic workflow for all PR checks

## Decision Outcome

Chosen option: "Adopt `check-pr-title.yml` and `check-branch-name.yml` from
`hasansezertasan/copier-pyproject`".

Both workflows are proven, static GitHub Actions gates:
1. `check-pr-title.yml` runs `amannn/action-semantic-pull-request` pinned by SHA
   to validate PR titles against Conventional Commits, with sticky comment
   feedback via `marocchino/sticky-pull-request-comment`. It enforces
   `scopes: [a-z0-9._/-]+` for optional lowercase scopes and
   `subjectPattern: ^.*[^.]$` to disallow trailing periods in PR titles,
   matching local PR rules.
2. `check-branch-name.yml` validates `github.head_ref` against Conventional
   Branch conventions using an inline Bash script without unmaintained action
   dependencies, providing matching sticky error comments. It aligns with
   repository branch policy by restricting types to
   `feature|bugfix|hotfix|release|chore` with kebab-case hyphen-separated
   descriptions and semantic bans on dead words and bare dates, while
   permitting automated branches (`renovate/*`, `release-please--*`).

Both workflows use per-PR concurrency groups with `cancel-in-progress: true` to
prevent race conditions from superseded runs, and safely run on
`pull_request_target` with `pull-requests: write` permissions so they can comment
on pull requests from forks without checking out or executing code from the PR.

### Consequences

* Good, because pull request titles and branch names are validated automatically
  on all incoming PRs.
* Good, because sticky PR comments provide immediate, actionable feedback to
  contributors when names fail validation.
* Good, because both workflows are dependency-pinned and safe against code
  injection from forks.
* Good, because maintaining two focused workflows keeps failure causes clear and
  independent in GitHub's status checks UI.
* Bad, because workflows running on `pull_request_target` require ongoing
  vigilance to ensure untrusted code is never checked out or run.

## Related Research

* [CI gates for pull request titles and branch names](../research/0010-ci-pr-title-and-branch-name-gates.md)
