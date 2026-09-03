# Declare GUI Applications in the Brewfile

## Context and Problem Statement

`bootstrap.sh` makes Zed the default handler for twenty-one file types with
`duti -s dev.zed.Zed`, but the `Brewfile` declared only formulae and no casks.
On a fresh machine `brew bundle install` therefore never installed Zed, and the
later `duti` calls registered a default handler for an absent application. The
same gap covered every other GUI application on this machine: sixty-two casks
were installed through Homebrew and none of them were declared.

## Considered Options

* Declare a curated set of casks, including the ones the bootstrap configures
* Declare only `zed`, the single cask the bootstrap depends on
* Commit the output of `brew bundle dump --casks --taps`
* Leave casks undeclared and install GUI applications by hand

## Decision Outcome

Chosen option: "Declare a curated set of casks, including the ones the
bootstrap configures", because the `Brewfile` is meant to describe a machine
worth reproducing rather than mirror the current one. `brew bundle dump` would
have added sixty-two casks and three further taps, most of them short-lived
experiments that do not belong in a bootstrap.

Declaring only `zed` was rejected for the opposite reason: it repairs the
`duti` call while leaving the daily applications undeclared, so the bootstrap
still would not produce a usable machine.

Adding an application is now a deliberate edit. The list is not expected to
stay in step with everything installed locally, and `brew bundle dump` should
not be used to regenerate it.

`brew bundle install` already runs before the macOS settings in `bootstrap.sh`,
so no reordering was needed: Zed is installed by the time the `duti` loop runs.

The `tailscale` formula and the `tailscale-app` cask are both declared. The
formula provides the CLI and daemon under the Homebrew prefix and the cask
installs the menu bar application, so they coexist rather than conflict.

### Consequences

* Good, because the `duti` file associations now refer to an application the
  bootstrap installs.
* Good, because a fresh machine gets the daily applications from the same one
  command as the command-line tools.
* Good, because a curated list keeps experiments out of the bootstrap.
* Bad, because the list will drift from what is installed locally, and closing
  that drift is a manual review rather than a dump.
* Bad, because casks are large downloads, so a first bootstrap on a new machine
  takes considerably longer.
* Bad, because a cask that is renamed or removed upstream breaks
  `brew bundle install` until the `Brewfile` is corrected.
