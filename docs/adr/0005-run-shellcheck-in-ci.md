# Run ShellCheck in CI

## Context and Problem Statement

`bootstrap.sh` and `link.sh` carry the whole installation, and both are long
enough that quoting and expansion mistakes are easy to miss. The repository had
no automated checks at all, so the preceding pull requests were verified by hand
and ShellCheck was not installed on the development machine. Nothing recorded
which files are expected to be lint-clean.

## Considered Options

* Run the runner's preinstalled ShellCheck from a GitHub Actions job
* Run ShellCheck through a third-party action such as `ludeeus/action-shellcheck`
* Run ShellCheck from a pre-commit framework
* Keep verifying shell changes by hand

## Decision Outcome

Chosen option: "Run the runner's preinstalled ShellCheck from a GitHub Actions
job", because GitHub-hosted runners already ship ShellCheck, which makes the
job a checkout plus a single command with no third-party action in the supply
chain and no version pinning to maintain.

The job runs `shellcheck ./*.sh`, so a new top-level script is covered without
editing the workflow. Zsh files under `zsh/` are excluded because ShellCheck
does not support the Zsh dialect. `shellcheck` was added to the `Brewfile` so
the same command can be run locally before pushing.

The two existing findings were both `SC2034` on `LOCALE` and
`MEASUREMENT_UNITS`, which are read only by commented-out `defaults` writes in
the Localization section. They are parked knobs rather than dead code, so they
keep a narrow `disable` directive instead of being deleted.

### Consequences

* Good, because shell changes are checked automatically instead of by hand.
* Good, because the workflow depends only on `actions/checkout` and a tool the
  runner already provides.
* Good, because `shellcheck ./*.sh` is the same command locally and in CI.
* Bad, because the ShellCheck version follows the runner image, so a runner
  update can introduce new findings in unchanged scripts.
* Bad, because the Zsh configuration remains unchecked.
* Bad, because a `disable` directive can outlive the commented-out code that
  justifies it.
