# Test link.sh against a Scratch HOME

## Context and Problem Statement

`link.sh` writes symlinks into `$HOME`, and the repository documents several
guarantees about how it behaves: it manages an explicit package list, keeps
shared directories real through `--no-folding`, refuses conflicting targets
instead of overwriting them, and reverses cleanly. Nothing checked any of that.
CI verified only that the script parses, and the guarantees had been confirmed
by hand each time the package list changed, which does not survive the next
change.

## Considered Options

* Run the real script against a scratch `HOME` from a test script in the
  repository
* Assert on `stow --simulate` output instead of performing the operations
* Run the test in a container with a disposable home directory
* Keep verifying link behaviour by hand

## Decision Outcome

Chosen option: "Run the real script against a scratch `HOME` from a test script
in the repository", because `link.sh` derives its target from `HOME` and its
package directory from its own location, so pointing `HOME` at a temporary
directory exercises the real code path without touching anything else. No
container or mocking layer is needed.

`link_test.sh` asserts that `install` creates each expected link and that every
link resolves inside the repository, that the shared directories remain real
directories, that `uninstall` leaves no links behind, that a pre-existing file
is refused by both `check` and `install` without being modified, and that an
unknown subcommand exits non-zero.

Parsing `stow --simulate` output was rejected because it would test Stow's
messages rather than the resulting file system, and those messages are not a
stable interface.

Each assertion was verified by breaking `link.sh` in a way it should catch and
confirming the test fails, rather than by observing that the test passes. The
mutations and results are in the research note.

The test lives at the repository root as a `.sh` file, so the existing
ShellCheck job covers it through the same pathspec as the other scripts.

### Consequences

* Good, because the documented link guarantees are checked on every push and
  pull request instead of by hand.
* Good, because the conflict-refusal behaviour that protects `$HOME` is pinned,
  including the all-or-nothing property of a failed run.
* Good, because a change to `PACKAGES` is verified rather than assumed.
* Good, because the same script runs locally and in CI, and is itself linted.
* Bad, because `EXPECTED_LINKS` and `EXPECTED_DIRS` duplicate the package
  layout, so adding a package means updating the test as well.
* Bad, because the test installs GNU Stow on the runner, which the other jobs
  do not need.
* Bad, because `restow` is left uncovered.

## Related Research

* [GNU Stow behaviour that link.sh relies on](../research/0006-stow-behaviour-relied-on-by-link-sh.md)
