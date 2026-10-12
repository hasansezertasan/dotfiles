# Route the Delegate Fleet through OpenCode

## Context and Problem Statement

The delegate-fleet configuration (`delegate-skills` package,
`delegate-fleet.v1`) routed every lane — `feature`, `tests`, `fast`,
`complex` — through the `agy` implementer on Gemini models, as recorded in
research 0011. Delegated implementation work has consolidated on OpenCode,
so the fleet now routes all four lanes through the `opencode` implementer
with per-lane models. A fleet-wide implementer and model switch is an
execution-policy decision; without a record it is indistinguishable from
incidental local churn.

## Considered Options

* Route all lanes through `opencode` with per-lane models (chosen)
* Keep the `agy`/Gemini fleet
* Mix implementers per lane

## Decision Outcome

Chosen option: "Route all lanes through `opencode` with per-lane models".

| Lane | Implementer | Model |
| --- | --- | --- |
| `feature` | `opencode` | `opencode-go/muse-spark-1.3-contributor` |
| `tests` | `opencode` | `openai/gpt-6-luna` |
| `fast` | `opencode` | `opencode-go/glm-5.3-flash` |
| `complex` | `opencode` | `openai/gpt-6.1-sol` |

### Consequences

* Good, because delegation lanes match the implementer actually in use.
* Good, because per-lane models keep cheap/fast tasks off the strongest
  models.
* Bad, because a future implementer move requires touching every lane again;
  the single-implementer layout has no fallback if OpenCode is unavailable.

## Related Research

* [Delegate fleet on OpenCode](../research/0018-delegate-fleet-opencode.md)
* [delegate-skills Configuration Investigation](../research/0011-delegate-skills-stow-package.md) (previous fleet snapshot)
