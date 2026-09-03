# GUI application inventory and Brewfile cask selection

Research snapshot: 2026-09-03, on the machine this repository configures
(macOS 26, Homebrew on `/opt/homebrew`, `arm64_tahoe`).

## Executive conclusion

The `Brewfile` declared no casks while 62 were installed through Homebrew, and
one of them is a hard dependency of `bootstrap.sh`. Declare a curated subset
rather than the output of `brew bundle dump`, which would also pull in three
taps the repository does not declare.

## `bootstrap.sh` depends on an undeclared application

`bootstrap.sh` makes Zed the default handler for twenty-one file types:

```
$ grep -nE 'brew bundle|duti -s' bootstrap.sh
48:brew bundle install --file "${DOTFILES_DIR}/Brewfile" --no-upgrade || exit 1
462:  duti -s dev.zed.Zed "${file_type}" all || EXIT_STATUS=1
```

With no cask declared, `brew bundle install` at line 48 never installed Zed, so
line 462 registered a default handler for an absent application on a fresh
machine. The line numbers also settle the ordering question: package
installation already precedes the file associations, so declaring the cask is
sufficient and no reordering is needed.

## Scale of the gap

```
$ brew list --cask | wc -l
62
$ grep -c '^cask' Brewfile
0
```

`brew bundle dump --casks --taps` emits 62 casks and four taps. Three of those
taps are absent from the `Brewfile`, which declares only
`hasansezertasan/tap`:

```
tap "hasansezertasan/tap"
tap "omnigent-ai/tap"
tap "stablyai/orca"
tap "yetidevworks/drydock"
```

A dump would therefore widen the repository's trust surface as a side effect of
recording applications, which is reason enough not to generate this list.

## Selection criterion

The 62 installed casks divide into daily drivers and short-lived experiments,
the latter being the larger group — `agentsmesh`, `agentsview`, `cc-pocket`,
`cc-switch`, `grok-bot`, `muse-code`, `thaw`, `waku`, `zedis` and the `open*`
set among them. A bootstrap should reproduce a machine worth working on, not
the current state of an experiment queue, so 21 were selected and the rest left
undeclared. Adding an application is a deliberate edit; `brew bundle dump`
should not be used to regenerate the list.

## `brew bundle check` needs `--no-upgrade` to answer the useful question

By default `brew bundle check` reports outdated packages as unsatisfied, which
conflates "missing" with "not the newest":

```
$ brew bundle check --file Brewfile --verbose
→ Cask chatgpt needs to be installed or updated.
→ Cask claude needs to be installed or updated.
→ Cask whatsapp needs to be installed or updated.
→ Cask zed needs to be installed or updated.
...
```

All four are installed. `bootstrap.sh` passes `--no-upgrade` to
`brew bundle install`, so the matching check is the one that reflects what the
bootstrap will actually do, and under it every declared cask is satisfied:

```
$ brew bundle check --file Brewfile --no-upgrade --verbose
→ Formula shellcheck needs to be installed.
→ Formula hasansezertasan/tap/{hwid,nur,ocom,peta} needs to be installed.
```

The remaining five are pre-existing drift from earlier work rather than
anything this selection introduced.

Cask tokens were also validated individually, since a typo in a token is only
discovered at install time on a fresh machine:

```sh
for c in $(grep '^cask' Brewfile | sed 's/cask "//;s/"//'); do
  brew info --cask "$c" > /dev/null 2>&1 || echo "unresolved: $c"
done
```

All 21 resolve.

## `tailscale` and `tailscale-app` do not conflict

Declaring both a formula and a cask for the same product looks like a mistake,
so it was checked. Neither Homebrew manifest declares a conflict, and the two
install to different places: the formula owns the executable under the Homebrew
prefix, and the cask is a `.pkg` that installs the menu bar application.

```
$ ls -l "$(command -v tailscale)"
/opt/homebrew/bin/tailscale -> ../Cellar/tailscale/1.102.3/bin/tailscale

$ brew list --cask tailscale-app | head -1
/opt/homebrew/Caskroom/tailscale-app/1.102.3/Tailscale-1.102.3-macos.pkg
```

There is no `PATH` collision, and both are installed and working on this
machine. The formula supplies the CLI and daemon; the cask supplies the GUI.

## Limitation

This list is a curated snapshot and will drift from what is installed locally.
Closing that drift is a manual review of `brew list --cask` against the
`Brewfile`, not a regeneration step.
