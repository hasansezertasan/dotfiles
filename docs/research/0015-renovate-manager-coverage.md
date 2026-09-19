# What Renovate's native managers reach in this repository

Research snapshot: 2026-09-19. Renovate `latest` from npm, run locally against
the `feature/adopt-renovate` branch.

## Executive conclusion

Five package files and seventeen dependency instances are reached by native
managers, with no `customManager` required. The result that could not be
assumed is the mise one: `mise/.config/mise/config.toml` sits inside a Stow
package rather than at a conventional repository location, and the mise manager
matches it anyway.

Three files that look like dependency manifests are not covered by anything:
`Brewfile`, `skills-lock.json`, and `agents/.agents/.skill-lock.json`.

## Method

Renovate's local platform extracts dependencies from a working directory
without touching GitHub:

```sh
GITHUB_COM_TOKEN="$(gh auth token)" \
  mise exec node@24 -- npx --yes renovate@latest --platform=local --dry-run=extract
```

Two things the invocation has to get right:

* Renovate declares `node ^24.11.0`. This machine runs node 26, where Renovate
  refuses to start with "Unsupported node environment detected" and exits 0 —
  so the run looks successful while extracting nothing. `mise exec node@24`
  supplies a supported runtime.
* `GITHUB_COM_TOKEN` is needed to resolve `github>hasansezertasan/renovate-config`.
  Without it the preset lookup is subject to unauthenticated rate limits.

The extraction is reported as a JSON log. Do not pipe it through `head` or
`tail` before reading it: the first attempt here used `tail -120`, which cut
two workflow files out of the log and made them look uncovered. Capture the
whole log to a file, then filter.

## Coverage

| Package file | Manager | Dependencies |
| --- | --- | --- |
| `.github/workflows/ci.yml` | github-actions | `actions/checkout` (×3), `ubuntu` runners |
| `.github/workflows/check-pr-title.yml` | github-actions | `amannn/action-semantic-pull-request`, `marocchino/sticky-pull-request-comment` |
| `.github/workflows/check-branch-name.yml` | github-actions | `marocchino/sticky-pull-request-comment` |
| `mise/.config/mise/config.toml` | mise | `bun`, `gcloud`, `uv` |
| `opencode/.config/opencode/package.json` | npm | `@opencode-ai/plugin` |

Seventeen dependency instances in total: `ubuntu` appears five times and
`marocchino/sticky-pull-request-comment` four, once per job that uses them.

### The mise file is matched despite its path

Every other repository would hold this file at `mise.toml` or
`.config/mise/config.toml`. Here it is at `mise/.config/mise/config.toml`,
because the leading `mise/` is the Stow package directory.

The mise manager's `defaultConfig`, read from the shipped
`dist/modules/manager/mise/index.js`, declares globs rather than anchored
regexes:

```js
managerFilePatterns: [
    "**/{,.}mise{,.*}.toml",
    "**/{,.}mise/config{,.*}.toml",
]
```

`**/` absorbs any leading directories, so the Stow prefix `mise/.config/` is
matched by it and the trailing `mise/config.toml` satisfies the rest of the
second pattern. Any depth of nesting would work the same way. The dry-run was
run precisely because this was not safe to assume from the path alone.

## What nothing covers

| File | Why no manager applies |
| --- | --- |
| `Brewfile` | Renovate's `homebrew` manager declares `managerFilePatterns: ["/^Formula/\\w*/?[^/]…"]`, so it reads tap formula definitions, not a `brew bundle` manifest. Nothing extracts `brew`/`cask` lines. |
| `skills-lock.json` | Skills CLI lock format; no Renovate datasource. Its entries carry a `source` and a `computedHash`, not a version. |
| `agents/.agents/.skill-lock.json` | Same format, managed through the `agents` Stow package. |

None of these is a candidate for a `customManager` as things stand. The two
lock files pin by content hash rather than by version, so there is no version
string for a regex to bump, and a `Brewfile` regex would have to encode the
Homebrew datasource by hand for every line — the duplication ADR 0014 warns
about. If `Brewfile` coverage is ever wanted, the right fix is upstream
support in the `homebrew` manager.

## Related decisions

* [Adopt Renovate with the shared preset](../adr/0018-adopt-renovate-with-the-shared-preset.md)
* [Prefer native Renovate managers over custom regex managers](../adr/0014-prefer-native-renovate-managers.md)
