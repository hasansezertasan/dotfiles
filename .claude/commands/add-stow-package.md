# Add a Stow Package

Add one or more tools' configuration to this dotfiles repository as GNU Stow
packages. The user names the tool(s); you investigate each config layout,
verify symlink safety, create the packages, wire them into the link and test
scripts, and document the decision.

When adding multiple packages at once (e.g. "add ssh, olink, and zed"), run
Steps 1-4 for all of them first (the research phase), then do Steps 5-8
together (one link.sh update, one link_test.sh update, one test run, one
install), update the README once for all packages (Step 9), and write a
single combined research doc and ADR covering all packages in the batch.

## Before you start

Read these files to understand the current state:

- `link.sh` — the `PACKAGES` array is the source of truth for managed packages
- `link_test.sh` — `EXPECTED_LINKS` and `EXPECTED_DIRS` define what the test asserts
- `.gitignore` — existing allowlist patterns for packages with sensitive siblings
- `docs/adr/` — existing ADRs (you need the next number)
- `docs/research/` — existing research docs (you need the next number)

Confirm the tool is not already in the `PACKAGES` array before proceeding.

## Step 1 — Inventory the tool's config

Find every file the tool keeps under `$HOME`. Typical locations:

- `~/.<toolname>` or `~/.<toolname>/`
- `~/.config/<toolname>/`
- `~/Library/Application Support/<toolname>/` (macOS apps)

For each file, determine:

| File | Size | Mode | Classification |
|------|------|------|----------------|
| path | bytes | octal | portable-config / credential / generated-state / cache / database / machine-specific |

**Portable config** = user-authored settings the user would want on a fresh machine.
Everything else stays unmanaged.

Classify carefully:
- Files containing tokens, API keys, passwords, or session data → **credential**, never track
- Files with absolute paths (e.g. `/Users/hasansezertasan/...`) → **machine-specific** unless the path can be replaced with `$HOME`
- Files written by installers, plugins, or the tool itself without user input → **generated-state**
- Lock files, `node_modules/`, `.db`, `.sqlite`, history files → **cache/database**

## Step 2 — Verify symlink write-through

The tool must write *through* a symlink, not replace it (ADR 0009's criterion, originally established in ADR 0004).

The established test method:

```bash
SCRATCH="$(mktemp -d)"
mkdir -p "${SCRATCH}/repo" "${SCRATCH}/cfg/<toolname>"

# Create a config file in the "repo" and symlink it
echo '<initial content>' > "${SCRATCH}/repo/<config-file>"
ln -s "${SCRATCH}/repo/<config-file>" "${SCRATCH}/cfg/<toolname>/<config-file>"

# Use the tool's own config command to change a setting.
# Pick a side-effect-free write command — one that only touches the config file
# and does not install plugins, download tools, or modify caches. If the write
# command has unavoidable side effects, redirect all affected state into
# ${SCRATCH} or clean up explicitly after the test.
<TOOL_CONFIG_ENV_VAR>="${SCRATCH}/cfg/<toolname>" <tool> <config-command> <setting> <value>

# Check: link survived AND value landed in repo copy
ls -l "${SCRATCH}/cfg/<toolname>/<config-file>"  # should be symlink
cat "${SCRATCH}/repo/<config-file>"               # should have new value

# Clean up scratch dir and any side effects (e.g. tool installations)
rm -rf "${SCRATCH}"
```

If the package manages **multiple files**, repeat this test for each file the
tool might write to. A file that is only read (not written by the tool) does not
need the test — note it as read-only in the research doc.

Each tool has its own env var for redirecting config. Some point to a
**directory**, others to a **file** — adjust the template accordingly:

- `GH_CONFIG_DIR` for gh (directory)
- `MISE_GLOBAL_CONFIG_FILE` for mise (file — point at the config file, not its parent)
- `ATUIN_CONFIG_DIR` for atuin (directory)
- Find the equivalent for the new tool in its docs

For a **file-valued** redirect, set it to `"${SCRATCH}/cfg/<toolname>/<config-file>"`
instead of the directory.

If the tool has no config command or env var redirect, only add files the tool
**never writes to** (read-only config). If the tool writes to its config but
write-through cannot be verified, do not add those files — stop and report.
If the tool replaces the symlink, it cannot be managed — stop and report.

## Step 3 — Create the package directory

The package mirrors the `$HOME` structure:

```
<toolname>/
└── <relative-path-from-HOME>
    └── <config-file>
```

Copy only the portable config files identified in Step 1.

If any file contains absolute home paths like `/Users/hasansezertasan`, replace
with `$HOME` where the tool supports variable expansion. If it doesn't, **exclude
that file** — a committed absolute path is invalid on any other machine.

The original config files still exist in `$HOME` at this point — they will be
handled in the install step (Step 8) after the test passes.

## Step 4 — Write gitignore allowlists

If the **source directory in `$HOME`** (from Step 1) contains files that must
NOT be tracked (credentials, generated state) beside the portable config, add
an allowlist block to the repo root `.gitignore`. Base this decision on the
source inventory, not the package directory — the package only has portable
files, but the tool may regenerate sensitive siblings through the symlink:

```gitignore
# <Toolname> keeps <description of sensitive/generated files> beside <managed file>.
<toolname>/<path>/*
!<toolname>/<path>/<managed-file>
```

Pattern: deny everything in the directory, then allow back only the managed files.
See existing patterns in `.gitignore` for `ssh/`, `codex/`, `zed/`, `opencode/`.

Skip this step if the source directory in `$HOME` contains only the managed
files with no sensitive siblings.

After writing patterns, verify both sides:

```bash
# Managed files must NOT be ignored
git check-ignore <toolname>/<path>/<managed-file>
# ↑ If this prints a path, the allowlist is too broad — fix the pattern.

# Excluded paths MUST be ignored
git check-ignore <toolname>/<path>/<excluded-file>
# ↑ If this prints nothing, the deny rule is incomplete — fix the pattern.
```

## Step 5 — Update `link.sh`

Add the package name to the `PACKAGES` array in **alphabetical order**.

## Step 6 — Update `link_test.sh`

Add entries to both arrays in **alphabetical order**:

**`EXPECTED_LINKS`** — every symlink the package creates.
Path is relative to `$HOME` (e.g. `.config/toolname/config.toml`).

**`EXPECTED_DIRS`** — every shared parent directory that `--no-folding` keeps as
a real directory (not a symlink). Include all intermediate directories.
For example, a file at `.config/toolname/config.toml` needs both `.config/toolname`
and `.config` (though `.config` likely already exists from other packages).

Only add directories not already in the array.

## Step 7 — Run the test

```bash
./link_test.sh
```

All checks must pass:
- Every expected link exists and points into the repository
- Shared directories are real directories (not symlinks)
- Uninstall removes every link
- A conflicting file is refused
- Unknown subcommands are rejected

If the test fails, fix the issue and re-run. Common problems:
- Forgot a directory in `EXPECTED_DIRS`
- Alphabetical order wrong (doesn't cause failure, but fix for consistency)
- Gitignore pattern too broad (blocks the managed file)

## Step 8 — Install on the real `$HOME`

The test (Step 7) validates the package in isolation. Now install it for real.

Back up the originals so `link.sh` can create the symlinks. Use a unique
suffix to avoid overwriting any pre-existing `.bak` from a previous attempt:

```bash
BACKUP_SUFFIX=".bak.$(date +%s)"
mv ~/.config/<toolname>/<config-file> ~/.config/<toolname>/<config-file>${BACKUP_SUFFIX}
```

Run the install and verify. If the install fails (e.g. a conflict from another
package), restore every backup immediately — do not leave the tool without its
config:

```bash
./link.sh install
if [ $? -ne 0 ]; then
  mv ~/.config/<toolname>/<config-file>${BACKUP_SUFFIX} ~/.config/<toolname>/<config-file>
  echo "Install failed — originals restored. Fix the conflict and retry."
  exit 1
fi
ls -l ~/.config/<toolname>/<config-file>  # should be a symlink into the repo
```

Before deleting backups, diff each against the package copy — the tool may have
written changes between Step 3 (copy) and now, especially if a GUI app was
running:

```bash
diff ~/.config/<toolname>/<config-file>${BACKUP_SUFFIX} <toolname>/<relative-path>/<config-file>
```

If they differ, reconcile (merge the newer changes into the package copy) before
removing the backup. If identical, delete safely.

## Step 9 — Update `README.md`

Add the new package to the README's managed-package documentation. Follow the
existing pattern: describe what the package links, what is deliberately
excluded, and any symlink or permission caveats.

## Step 10 — Write the research doc

Create `docs/research/NNNN-<slug>.md` (next sequential number).

Structure (follow the pattern in existing research docs):

```markdown
# <Title describing the investigation>

Research snapshot: <date> on macOS <version>.

## Executive conclusion

<2-3 sentences summarizing findings and recommendation>

## Inventory method

<How you found the files, what you checked>

## <Tool-specific findings>

<Symlink safety results, managed vs unmanaged table, credential analysis,
permission implications of 644 vs 600>
```

## Step 11 — Write the ADR

Create `docs/adr/NNNN-<slug>.md` (next sequential number).

Use MADR format (see existing ADRs for the exact template):

```markdown
# <Decision title>

## Context and Problem Statement

<What configuration exists, why it matters>

## Considered Options

* <Option A>
* <Option B>
* <Option C>
* <Option D>

## Decision Outcome

Chosen option: "<option>", because <reason>.

<Details of what's managed, what's excluded, and why>

### Consequences

* Good, because <benefit>
* Bad, because <tradeoff>

## Related Research

* [<title>](../research/<file>.md)
```

## Checklist

Before reporting done:

- [ ] Config files inventoried and classified
- [ ] Symlink write-through verified for every writable file (read-only files exempt)
- [ ] Package directory created with only portable config
- [ ] Gitignore allowlist added (if needed, based on source inventory) and `git check-ignore` passes
- [ ] `link.sh` PACKAGES updated (alphabetical)
- [ ] `link_test.sh` EXPECTED_LINKS and EXPECTED_DIRS updated (alphabetical)
- [ ] `./link_test.sh` passes
- [ ] Original config backed up, `./link.sh install` run, symlinks verified
- [ ] `README.md` package documentation updated
- [ ] Research doc written
- [ ] ADR written
- [ ] All changes committed
