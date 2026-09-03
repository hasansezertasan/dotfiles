# Declare Tap Trust in the Brewfile

## Context and Problem Statement

Homebrew refuses to load a formula from a third-party tap until that tap or
formula is trusted, and `brew bundle install` cannot prompt for the decision.
The `Brewfile` declared six formulae from `hasansezertasan/tap` behind a bare
`tap "hasansezertasan/tap"` line, of which only two had ever been trusted on
this machine, and trust is machine-local state rather than tap content.

`bootstrap.sh` guards dependency installation with `|| exit 1`, so this did not
degrade to a missing tool. The bootstrap aborted before the Stow links and the
macOS settings were applied, after having already installed the packages
declared earlier in the file. A fresh machine fails sooner, on the first
formula, because it has no trust for the tap at all.

## Considered Options

* Declare the trusted formulae inline on the `tap` line
* Run `brew trust hasansezertasan/tap` from `bootstrap.sh` before `brew bundle`
* Document a manual `brew trust` step as a prerequisite
* Drop the tap formulae from the `Brewfile`

## Decision Outcome

Chosen option: "Declare the trusted formulae inline on the `tap` line", using
the syntax `brew bundle dump` itself emits, because it keeps the run
non-interactive without adding a second package-management command to
`bootstrap.sh`, and it makes the trusted set explicit and reviewable in the
same file that declares the formulae.

Trusting the tap is reasonable here specifically because it is the repository
owner's own tap. The declaration names each formula rather than trusting the
tap wholesale, so adding a formula to the tap does not silently become trusted
by this repository.

A `brew trust` call in `bootstrap.sh` was rejected because it would place
trust state in an imperative step while the packages it applies to are
declared elsewhere, and a documented manual prerequisite was rejected because
it reintroduces the manual step ADR 0003 removed.

### Consequences

* Good, because `brew bundle install` completes, so `bootstrap.sh` reaches the
  link and macOS stages on a fresh machine.
* Good, because the trusted formulae are declared next to the formulae
  themselves rather than accumulated by hand per machine.
* Good, because trust is granted per formula, not to the whole tap.
* Bad, because a new formula added to the personal tap must be added to the
  trust list as well as the install list.
* Bad, because nothing in CI catches this class of failure: it depends on
  Homebrew, a tapped third-party tap, and machine-local trust state, none of
  which exist on the Linux runners.
* Bad, because the bootstrap has still never been run end to end on a clean
  machine, which is the only thing that would have caught this earlier.

## Related Research

* [Homebrew tap trust and non-interactive brew bundle runs](../research/0008-homebrew-tap-trust-in-brew-bundle.md)
