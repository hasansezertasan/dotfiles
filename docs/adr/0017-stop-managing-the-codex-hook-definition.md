# Stop Managing the Codex Hook Definition

## Context and Problem Statement

ADR 0011 added `codex` as a narrow Stow package managing a single file,
`~/.codex/hooks.json`, with the hook command's absolute home path replaced by
`$HOME` so the definition would work on any machine. That substitution has not
held. The writer is Orca's managed hook runtime, shipped inside the application
bundle at `Orca.app/Contents/Resources/relay/<platform>/managed-hook-runtime.js`.
It rewrites the file with the expanded path,
`/Users/hasansezertasan/.orca/agent-hooks/codex-hook.sh`, in all eight hook
entries, and writes a `hooks.json.bak` beside it as it does so.

The runtime never emits `$HOME` for this path. It builds the location with
`path.join(os.homedir(), ".orca", "agent-hooks", <script>)`, resolving the home
directory in Node at write time, and then single-quotes the result when
composing the `sh` command, so nothing it generates can carry a shell variable.
The only `$HOME` literals in the bundle belong to an unrelated
endpoint-discovery snippet. The committed `$HOME` form was itself valid — the
path was assigned inside double quotes, which `/bin/sh` expands, and the hook
ran — so the obstacle is not the file format but that the form does not
survive: a reconciliation path, which logs as `[codex-hook-promotion]`,
compares the file against the definition it expects and rewrites it when they
differ, which is why a restored file is undone on the next launch rather than
at some later point.

Because the managed path is a symlink into this repository, each rewrite lands
in the working tree and the repository reports a modification. Restoring the
committed version does not settle it: on 2026-09-18 the file was restored at
23:17 and rewritten again at 23:18, with the backup's timestamp moving to
match. The package therefore produces a permanent dirty working tree and
invites a machine-specific path into the repository on any commit made without
checking.

This inverts the criterion ADR 0004 set and ADR 0009 applied. Those ADRs asked
whether an application writes *through* a symlink rather than replacing it.
Codex passes that test — the link survives every rewrite — but the criterion
was chosen as a proxy for whether the managed content stays portable, and here
it does not.

## Considered Options

* Stop managing `hooks.json` and remove the `codex` package
* Keep the package and restore `$HOME` whenever the file is rewritten
* Keep the package and commit the expanded path
* Find and reconfigure the installer so it emits `$HOME`

## Decision Outcome

Chosen option: "Stop managing `hooks.json` and remove the `codex` package".
`hooks.json` is deleted from the repository, `codex` is removed from the fixed
package list in `link.sh`, its link and shared directory assertions are removed
from `link_test.sh`, and its `.gitignore` allowlist is dropped with it. The
package managed only this one file, so nothing else in `~/.codex` changes
status: authentication, history, sessions, databases, caches, and `config.toml`
were already excluded by ADR 0011 and remain unmanaged.

The live file was converted back to a real file at `~/.codex/hooks.json` before
the package was removed, so Codex keeps its hooks on this machine.

Restoring `$HOME` on each rewrite was rejected because the rewrite is
automatic and the restore is manual; the two cannot stay in step. Committing
the expanded path was rejected because a hardcoded home directory in a dotfiles
repository defeats the purpose of restoring it on another machine, and because
the repository's own tooling flags such paths as machine-specific.

Reconfiguring the writer was rejected on inspection rather than left
untried. The path is hardcoded by construction in a vendored application
bundle, with no setting that changes it, so the only way to keep a portable
definition in place would be to patch Orca itself and re-patch it after every
update. If a
future Orca release emits a home-relative path, the package can be reinstated
by superseding this record.

### Consequences

* Good, because the working tree stops reporting a modification that no one
  made deliberately.
* Good, because a machine-specific absolute path can no longer reach a commit
  through this file.
* Good, because the package list now contains only tools whose managed content
  is actually portable.
* Bad, because a fresh machine no longer restores the Codex hook definition;
  it has to be installed by whatever writes it in the first place.
* Bad, because the reason is recorded here rather than fixed at its source, so
  the underlying rewrite still happens and will affect anything else that
  manages this file.

## Related Research

* [How Orca rewrites the Codex hook definition](../research/0013-orca-codex-hook-rewrite.md)
* [Boundaries for additional Stow packages](../research/0009-additional-stow-package-boundaries.md)
* [Symlink safety of the candidate application configurations](../research/0007-symlink-safety-of-cli-tool-config.md)
