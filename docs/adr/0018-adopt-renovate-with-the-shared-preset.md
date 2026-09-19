# Adopt Renovate with the Shared Preset

## Context and Problem Statement

Nothing in this repository updates its pinned dependencies. The global mise
configuration pins `bun`, `gcloud`, and `uv` at exact versions, and the CI
workflows pin their actions by commit SHA — both deliberate, and both
guaranteed to go stale silently, because an exact pin never moves on its own.
ADR 0015 named that cost when it introduced the mise pins and deferred the fix
to "until this repository adopts an automated updater".

The repository already assumes Renovate exists without ever running it. The
branch-name gate whitelists `renovate/*` so its pull requests are never blocked
(ADR 0012), and the global instructions carry a rule about preferring native
managers over `customManager` (ADR 0014) that has had nothing to apply to.

A second repository, `hasansezertasan/renovate-config`, already holds the
Renovate configuration shared across this author's projects.

## Considered Options

* Extend the shared preset, `github>hasansezertasan/renovate-config`
* Write a standalone configuration in this repository
* Keep updating pins by hand

## Decision Outcome

Chosen option: "Extend the shared preset". `.github/renovate.json` contains
nothing but the schema reference and the preset:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>hasansezertasan/renovate-config"]
}
```

The preset supplies `config:recommended`, `helpers:pinGitHubActionDigests`,
semantic commit messages, a dependency dashboard, the `internal` label, and one
documented `customManager` for `prek.toml` — which this repository does not
have, so that manager stays inert here.

Keeping the file to one line of policy means this repository inherits changes
made once in the preset rather than drifting from its siblings. It also keeps
ADR 0014's rule intact by construction: the native managers arrive configured,
and the only regex manager in the preset carries the `description` explaining
why no native manager fits it.

A local dry-run confirms what the native managers reach here rather than
leaving it to assumption: five package files and seventeen dependency
instances, across the three workflows, the mise pins, and the OpenCode plugin
manifest. The result worth checking was mise's: the file sits at a Stow package
path, `mise/.config/mise/config.toml`, and the manager matches it regardless.
No `customManager` is needed for anything in this repository, which is the
outcome ADR 0014 asks for. The method, the full coverage table, and the three
manifest-shaped files that no manager reaches are recorded in research 0015.

Two existing decisions line up with this without further work. Semantic commit
messages satisfy the Conventional Commits gate on pull request titles, and
`renovate/*` branches are already whitelisted by the branch-name gate, so
Renovate's pull requests pass both checks that ADR 0012 introduced.

### Consequences

* Good, because the mise pins and the workflow action digests now have
  something that proposes updates for them.
* Good, because configuration lives in one place for every repository that
  extends the preset.
* Good, because pinning action digests is enforced rather than remembered.
* Bad, because this repository's behaviour now depends on a second repository;
  a mistake in the preset reaches every consumer at once.
* Bad, because the preset's `internal` label has to exist in each repository
  that adopts it, or Renovate logs a warning and leaves its pull requests
  unlabelled. It was created here when this decision was taken.
* Bad, because Renovate now proposes changes inside managed dotfiles:
  `opencode/.config/opencode/package.json` is symlinked into `$HOME`, so a
  merged update changes live configuration, not just repository content.

## Related Research

* [What Renovate's native managers reach in this repository](../research/0015-renovate-manager-coverage.md)
