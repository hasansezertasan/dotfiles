# Share Hand-Authored Skills Across Agents

## Context and Problem Statement

The `add-stow-package` and `find-stow-candidates` workflows lived in
`.claude/commands/`, which only Claude Code reads. They were migrated to skills
(`.claude/skills/<name>/SKILL.md`, per
[anthropics/claude-code#37447](https://github.com/anthropics/claude-code/issues/37447),
which tracks the retirement of commands in favour of skills), but opencode,
Codex and other agents do not read `.claude/`. They do read `.agents/skills/`,
which this repository already tracks as generated content
([ADR 0019](0019-track-generated-project-skills.md)).

## Considered Options

* Keep the skills only in `.claude/skills/`
* Canonical copy in `.agents/skills/`, symlinked from `.claude/skills/`
* Canonical copy in `.claude/skills/`, symlinked from `.agents/skills/`
* A separate hand-authored directory symlinked into both

## Decision Outcome

Chosen option: "Canonical copy in `.agents/skills/`, symlinked from
`.claude/skills/`", because `.agents/skills/` is the location opencode and
Codex read natively, and Claude Code only needs a symlink. This mirrors how
`~/.claude/skills/` already points into `~/.agents/skills/` globally.

Both skills are manual-only, as they were as commands (`add-stow-package`
replaces files in `$HOME`). Each agent has its own switch: `SKILL.md` sets
Claude Code's `disable-model-invocation: true`, and `agents/openai.yaml` sets
Codex's `policy.allow_implicit_invocation: false`. Because they are not listed in `skills-lock.json`, the two skill
directories are excluded from the `linguist-generated` rule in
`.gitattributes` so reviews show their diffs.

### Consequences

* Good, because one copy serves Claude Code, opencode, Codex and other agents.
* Good, because the migration off `.claude/commands/` is complete.
* Bad, because hand-authored and generated skills share `.agents/skills/`;
  each new hand-written skill needs its own `.gitattributes` carve-out.
* Bad, because `npx skills experimental_install` may not preserve skills
  absent from `skills-lock.json`; verify after running it.
