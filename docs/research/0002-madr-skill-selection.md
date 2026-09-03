# MADR skill selection

Research snapshot: 2026-09-03.

## Goal

Find a maintained agent skill for recording repository decisions with Markdown
Architectural Decision Records (MADR).

## Findings

The skills ecosystem contained several ADR-oriented options. The strongest fit
was
[`wshobson/agents@architecture-decision-records`](https://www.skills.sh/wshobson/agents/architecture-decision-records):
it explicitly supports standard MADR, had approximately 15.8K installs, and its
source repository had approximately 39.4K stars at the time of review. The
listing also reported passing Gen Agent Trust Hub and Socket audits, with a low
Snyk risk rating.

Lower-adoption alternatives included
[`existential-birds/beagle@adr-writing`](https://skills.sh/existential-birds/beagle/adr-writing)
and
[`microsoft/hve-core@adr-author`](https://skills.sh/microsoft/hve-core/adr-author).
The broader
[`wshobson/agents`](https://github.com/wshobson/agents) repository is MIT
licensed and documents direct installation through the Skills CLI.

The official [MADR project](https://github.com/adr/madr) supplies minimal and
full templates. Its documentation defaults to `docs/decisions/` but explicitly
states that MADR does not enforce a repository layout. This repository instead
uses `docs/adr/`, matching the selected skill's recommendation and keeping the
artifact type visible in the path.

## Result

Install and use `wshobson/agents@architecture-decision-records`. Record project
decisions as sequential MADR documents under `docs/adr/`.

The Skills CLI calls its project dependency file `skills-lock.json`. A
project-scoped install records the upstream source, skill path, and computed
content hash there, while `npx skills experimental_install` restores the local
skill files. The generated `.agents/skills/` tree does not need to be versioned.
