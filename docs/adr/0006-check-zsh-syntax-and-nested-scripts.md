# Check Zsh Syntax and Nested Scripts in CI

## Context and Problem Statement

The CI job introduced in ADR 0005 ran `shellcheck ./*.sh`, which covers only
top-level scripts, and that record listed the unchecked Zsh configuration as a
known consequence. Both gaps became concrete: an open pull request adds
`claude/.claude/skills/pr/scripts/preflight.sh`, which the glob does not match,
and the `zsh` package is the largest tracked configuration with no check at all.

## Considered Options

* Select files with a Git pathspec and add a `zsh -n` parse check
* Extend the glob by hand for each new directory
* Run `shellcheck --shell=bash` over the Zsh files
* Leave nested scripts and the Zsh package unchecked

## Decision Outcome

Chosen option: "Select files with a Git pathspec and add a `zsh -n` parse
check", because `git ls-files` resolves the file list from what is tracked, so
a new script or Zsh fragment is covered without editing the workflow.

`shellcheck --shell=bash` was rejected for the Zsh files: it reports the Zsh
dialect as errors rather than checking it, so it cannot distinguish a real
mistake from valid Zsh. `zsh -n` parses without executing, which suits files
that source a framework and set up completions.

`zsh -n` requires one invocation per file. It reads a single script and treats
any further arguments as positional parameters, so `zsh -n good.zsh broken.zsh`
exits successfully and checks only the first file. This was verified against a
deliberately broken fragment before the workflow was written, and `xargs -n1`
is what keeps the check honest.

The Zsh job installs `zsh` with `apt-get` rather than assuming the runner image
provides it.

### Consequences

* Good, because scripts at any depth are checked, including the one in the
  pending pull request.
* Good, because the Zsh package is no longer completely unchecked.
* Good, because the file lists follow the repository instead of a hand-edited
  glob.
* Good, because the same two commands run locally and in CI.
* Bad, because `zsh -n` only checks syntax; it cannot find the logic and
  quoting problems that ShellCheck reports for Bash.
* Bad, because the Zsh job pays an `apt-get` install on every run.
* Bad, because `xargs -n1` is load-bearing in a way that is easy to
  "simplify" back into a silently passing check.
