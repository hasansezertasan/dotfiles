# CI gates for pull request titles and branch names

Research snapshot: 2026-09-10.

## Goal

Evaluate and adopt automated CI linting workflows from
[`hasansezertasan/copier-pyproject`](https://github.com/hasansezertasan/copier-pyproject)
to enforce Conventional Commits in pull request titles and Conventional Branch
naming on incoming branches.

## Context

This repository enforces commit and branch naming conventions locally through the
`pr` skill (`claude/.claude/skills/pr/`), which runs `preflight.sh` to check
branches and commit messages before opening a PR. However, the repository lacked
server-side GitHub Actions workflows to validate pull requests automatically.
Contributors or external pull requests were not guarded by automated status
checks.

In `copier-pyproject`, two dedicated, static GitHub Actions workflows provide
reusable, secure CI gates for PR validation:

1. `check-pr-title.yml`
2. `check-branch-name.yml`

## Analysis of the candidate workflows

### PR title validation (`check-pr-title.yml`)

The workflow validates the pull request title against the [Conventional Commits
specification](https://www.conventionalcommits.org/en/v1.0.0/) using the pinned
action `amannn/action-semantic-pull-request@48f256284bd46cdaab1048c3721360e808335d50` (v6).

Key architectural properties:
- **Trigger**: `pull_request_target` with types `[opened, edited, synchronize, reopened]`.
- **Permissions**: Restricted to least-privilege `pull-requests: write`.
- **Security**: Because squash-merge takes the PR title as the squashed commit
  message, PR titles must conform. Running under `pull_request_target` enables
  posting sticky comments on PRs from forks where `pull_request` receives a
  read-only token. It is safe because no repository code from the PR is checked
  out or executed.
- **Scope and subject restrictions**: Configured with `scopes: | \n [a-z0-9._/-]+`
  to match the repository's optional lowercase scope grammar, and
  `subjectPattern: ^.*[^.]$` to reject trailing periods in PR titles, aligning
  server-side validation with local `preflight.sh` and `SKILL.md` rules.
- **Concurrency**: Governed by `concurrency.group` keyed to the PR number with
  `cancel-in-progress: true` to prevent race conditions from superseded runs
  re-posting outdated sticky error comments.
- **Feedback**: Uses `marocchino/sticky-pull-request-comment@5770ad5eb8f42dd2c4f34da00c94c5381e49af88`
  (v3.0.5) to post a descriptive error comment if the title does not conform, and
  automatically deletes the comment once the title is corrected.

### Branch name validation (`check-branch-name.yml`)

The workflow checks the PR head branch name (`github.head_ref`) against the
[Conventional Branch](https://conventionalbranch.org/) specification (`<type>/<description>`).

Key architectural properties:
- **Dependency-free execution**: Implemented as an inline Bash script using regex
  matching, avoiding unmaintained third-party actions or deprecated Node runtimes.
- **Allowed types and semantic bans**: Aligned with this repository's branch
  policy in `preflight.sh` and `SKILL.md`:
  - Purpose prefixes: `feature`, `bugfix`, `hotfix`, `release`, `chore` (excluding
    short forms like `feat`/`fix` and AI-agent prefixes)
  - Descriptions: hyphen-separated lowercase alphanumerics only (excluding periods)
  - Semantic bans: rejects standalone dead words/placeholders (`wip`, `tmp`,
    `test`, etc.) and bare date descriptions
- **Whitelists**: Allows automated branches such as `renovate/*` and `release-please--*`.
- **Concurrency**: Governed by `cancel-in-progress: true` to cancel superseded
  checks on new pushes.
- **Security**: The untrusted `github.head_ref` is passed strictly through the
  `BRANCH_NAME` environment variable rather than inline `${{ github.head_ref }}`
  interpolation, preventing script injection. No PR code is checked out.
- **Feedback**: Shares the same sticky comment mechanism as `check-pr-title.yml`
  under header `branch-name-lint-error`.

## Compatibility with existing dotfiles tooling

The adopted workflows directly reinforce the dotfiles repository's existing
standards:
- All historical squash commits in this repository use Conventional Commits
  (e.g., `feat(...)`, `fix(...)`, `ci(...)`).
- The branch naming rules and subject validation match the exact policies
  documented in `claude/.claude/skills/pr/SKILL.md` and checked in `preflight.sh`.

## Conclusion

Adopt both workflows into `.github/workflows/`, configured to mirror the local
PR and branch naming constraints. They require no template substitution,
introduce no insecure checkout patterns, and provide automated feedback for all
incoming pull requests.
