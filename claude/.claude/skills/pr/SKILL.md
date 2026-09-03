---
name: pr
description: Open a pull request with a conventional branch name, commit message, and PR title, then hand the mechanics to /commit-commands:commit-push-pr. Use this whenever the user wants to open, raise, send, or ship a PR — "/pr", "open a PR", "push this and make a PR", "let's get this reviewed" — and also when they ask whether a branch name is acceptable, want a branch renamed to conform, or need a non-conventional commit message fixed before it is pushed. Especially use it when work is finished on a branch whose name carries a username, an agent name, or a generated workspace codename, since that name has to be corrected before anything reaches origin.
---

# Opening a pull request

`/commit-commands:commit-push-pr` already does the mechanics — branch, commit, push,
`gh pr create` — in a single message. It has no opinion about *naming*, and naming is
the part that is hard to undo once pushed. So this skill front-loads every decision and
correction, then lets that command execute a clean situation.

Work in this order. Each step exists because doing it after the push is expensive.

## 1. Pre-flight

Run the bundled report and read it before touching anything:

```bash
bash ~/.claude/skills/pr/scripts/preflight.sh
```

It answers the five things that drive every later decision: what branch you are on,
whether it already exists on origin, whether its name conforms, whether the unpushed
commits are conventional and attribution-free, and whether a PR is already open.

Note `on origin` in particular — it is the difference between a free rename and a
disruptive one.

## 2. Name the change once

A branch, a commit subject, and a PR title all describe the same change, so make **one**
decision and render it three ways. Deciding three times is how they drift apart.

Read the actual diff, then pick a type, an optional scope, and a short imperative
description of the change's *effect*:

| The change | Commit + PR type | Branch type |
| --- | --- | --- |
| Adds a capability | `feat` | `feature` |
| Fixes broken behaviour | `fix` | `bugfix` |
| Fixes production, urgently | `fix` | `hotfix` |
| Prepares a release | `chore` | `release` |
| Anything else — `docs`, `refactor`, `test`, `build`, `ci`, `perf`, `style`, `chore` | that type | `chore` |

The commit type is precise; the branch type stays inside Conventional Branch's five, so
branch names remain predictable to skim. Precision lives in the commit, not the branch.

Render the decision:

- **Commit subject / PR title** — `<type>(<scope>): <description>`, imperative, no
  trailing period. Add `!` or a `BREAKING CHANGE:` footer for a breaking change.
- **Branch** — `<branch-type>/<description-in-kebab-case>`, lowercase, hyphens only.
  Prefix the ticket when one exists: `feature/issue-123-add-login`.
- **PR body** — a line or two of plain prose. The title carries the meaning; skip
  ceremony. Add `Closes #123` when an issue is genuinely closed by this change.

Worked example, from a diff adding `claude/.claude/CLAUDE.md` and a stow package:

```
type feat, scope claude, effect "add global CLAUDE.md as a stow package"

branch  feature/add-global-claude-md
commit  feat(claude): add global CLAUDE.md as a stow package
title   feat(claude): add global CLAUDE.md as a stow package
body    Links ~/.claude/CLAUDE.md back into the dotfiles repo via stow.
```

### The branch description names the change, not who or what made it

A branch name is read by people scanning a branch list, and the author is already
recorded in every commit. Repeating it there costs a reader attention and tells them
nothing. So the description says what the change *does*.

That rules out: your git username or handle; agent and tool names (`claude`, `ai`,
`bot`, `agent`, `codex`, `cursor`); generated workspace codenames like `elephantfish`
that mean nothing to a reviewer; bare dates; and placeholders (`wip`, `tmp`, `test`,
`misc`, `update`, `changes`) that describe no change at all.

The pre-flight catches the mechanical cases by word match. It cannot recognise every
generated codename, so apply the real test yourself: **could a reviewer guess what
this PR does from the branch name alone?**

## 3. Fix the branch before pushing

- **Non-conforming and not on origin** — rename in place: `git branch -m <new-name>`.
  The old name was never published, so nothing downstream breaks and the commits are
  untouched.
- **Non-conforming but already on origin** — stop and ask. Renaming a published branch
  orphans the remote ref, breaks every existing checkout, and can detach an open PR. The
  user decides whether the tidier name is worth that; carrying on with the ugly name is
  often correct.
- **On the default branch** — pick the conforming name now and let
  `/commit-commands:commit-push-pr` create it.
- **Already conforming** — leave it alone.

## 4. Leave the history clean

The pre-flight lists every unpushed commit and flags any that are non-conventional or
carry AI attribution (the machine-wide policy in `~/.claude/CLAUDE.md` — no
`Co-Authored-By` naming an agent, no "Generated with" footers, nothing hinting the work
was done by an agent, in commits, titles, bodies, comments, or docs).

Fix what it flags, scaled to where the problem sits:

- Only the tip commit is wrong → `git commit --amend`.
- Deeper commits are wrong → report which ones and let the user choose. Interactive
  rebase is unavailable in this environment, so a rewrite means a non-interactive
  `git rebase --exec` or a soft reset and recommit; both are worth an explicit yes.
- Nothing unpushed is wrong → say so and move on.

## 5. Hand off

With the branch named, the history clean, and the three names decided, invoke:

```
/commit-commands:commit-push-pr
```

It expects to run as tool calls in a single message with no commentary, which is exactly
what a fully-decided situation allows. Use the names from step 2 verbatim — the commit
subject, the branch, and the PR title were chosen together and should stay identical.

If the pre-flight found a PR **already open** for this branch, do not create another
PR. Keep the command's commit and push operations, omit only `gh pr create`, and report
the existing PR's URL. Two PRs for one branch is a mess to unpick.

## After

Report the PR URL, the branch name, and the commit subject, so the user can see the
three names agree without opening anything.
