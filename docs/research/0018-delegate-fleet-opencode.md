# Delegate fleet on OpenCode

Research snapshot: 2026-10-12.

## Executive conclusion

`delegate-skills/.config/delegate-skills/config.json` (`delegate-fleet.v1`)
now routes every lane through the `opencode` implementer instead of `agy`:
`feature` on `opencode-go/muse-spark-1.3-contributor`, `tests` on
`openai/gpt-6-luna`, `fast` on `opencode-go/glm-5.3-flash`, `complex` on
`openai/gpt-6.1-sol`. Research 0011 stays untouched as the snapshot that
recorded the previous `agy`/Gemini fleet; this note records the new one.

## Inventory method

Diffed the managed config against its committed revision; no other files live
in the package directory, so the change is confined to lane routing. The file
remains portable (no credentials, no machine-specific paths, mode `644`),
consistent with the classification in research 0011.

## Findings

| Lane | Before | After |
| --- | --- | --- |
| `feature` | `agy`, no model | `opencode`, `opencode-go/muse-spark-1.3-contributor` |
| `tests` | `agy`, `gemini-3.8-flash-medium` | `opencode`, `openai/gpt-6-luna` |
| `fast` | `agy`, `gemini-3.8-flash-low` | `opencode`, `opencode-go/glm-5.3-flash` |
| `complex` | `agy`, `gemini-3.1-pro-high` | `opencode`, `openai/gpt-6.1-sol` |

Every lane changed implementer and model at once, so this is an
execution-policy decision rather than incidental churn, and it is recorded
as such in ADR 0021.
