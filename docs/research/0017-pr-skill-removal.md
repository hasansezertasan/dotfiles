# Removing the vendored pr skill

Research snapshot: 2026-10-12.

## Executive conclusion

The `pr` skill (`SKILL.md`, `scripts/preflight.sh`,
`scripts/test_preflight.sh`) was deleted from the `claude` Stow package.
The skill is maintained outside this repository and consumed from the global
skills installation (`~/.agents/skills/pr/`); nothing in this repository
replaces it. Three follow-ups keep the removal clean:

1. `link.sh` drops the three stale `~/.claude/skills/pr/...` links (with an
   ownership check) and removes directories left empty, mirroring the ADR
   0017 Codex-hook migration. Skill files are read-only, so unlike the Codex
   hook there is no write-through content to recover.
2. ADR 0012's reference to the local skill gains a supersession note; the new
   decision record below carries the current policy. Research 0010 stays
   untouched as a dated snapshot of the pre-removal state.
3. `check-branch-name.yml` no longer names the skill; the branch policy lives
   in the workflow itself.

## Inventory

| Path | State after removal |
| --- | --- |
| `claude/.claude/skills/pr/` | deleted from the package |
| `~/.claude/skills/pr/...` on old machines | dropped by `link.sh` install/restow/uninstall |
| `~/.agents/skills/pr/` | global install, outside this repository's management |
| `check-branch-name.yml`, `check-pr-title.yml` | unchanged gates, no skill reference |
