# Tracking generated project skills

Research snapshot: 2026-10-12.

## Executive conclusion

The generated project-skill tree (`.agents/skills/`, currently 3 files:
`architecture-decision-records/SKILL.md`, `research/SKILL.md`,
`research/agents/openai.yaml`) is now tracked in version control and marked
as auto-generated via `.gitattributes`
(`.agents/skills/** linguist-generated=true`), instead of gitignored.
`skills-lock.json` remains the provenance manifest (source, skill path,
content hash per skill); the tracked files are its installed output, and
`npx skills experimental_install` can still regenerate them.

## Inventory

| File or directory | Classification |
| --- | --- |
| `skills-lock.json` | portable manifest (source, path, hash per skill) |
| `.agents/skills/` | generated installed skill trees, now tracked |
| `.gitattributes` | marks `.agents/skills/**` as `linguist-generated` |

## Why the reversal

ADR 0002 chose lockfile-only tracking to avoid duplicating upstream skill
contents and to keep diffs focused. In practice the ignored tree made skill
changes invisible in pull requests and left fresh checkouts without project
skills until a restore command was run. Tracking the tree makes skill updates
reviewable alongside the lockfile change and keeps checkouts working without
a restore step.

## Costs and mitigations

* Diffs get noisier when upstream skills change. Mitigated by the
  `linguist-generated` marker, which collapses the diff in review UI, and by
  the do-not-hand-edit note in `.gitattributes`.
* Hand edits to generated files would be overwritten by the next install.
  Mitigated by the same do-not-edit note; the lockfile stays the source of
  truth for provenance.
