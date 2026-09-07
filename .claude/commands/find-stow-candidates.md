# Find Stow Candidates

Scan `$HOME` for tools whose configuration could become a new Stow package in
this dotfiles repository. Produce a research document with an inventory table,
symlink safety assessment, and actionable next steps.

## Before you start

Read `link.sh` to get the current `PACKAGES` array — these tools are already
managed and should be skipped. Also skim a couple of existing research docs in
`docs/research/` (especially `0007` and `0009`) to match the established
format and depth.

## Step 1 — Scan config locations

Check these locations for user-authored configuration:

```bash
# Dotfiles and dot-directories directly under $HOME
ls -la ~/.[!.]* 2>/dev/null

# XDG config directory
ls -la ~/.config/ 2>/dev/null

# macOS application support (for GUI apps in the Brewfile)
ls ~/Library/Application\ Support/ 2>/dev/null

# macOS preferences and sandboxed containers
ls ~/Library/Preferences/ 2>/dev/null
ls ~/Library/Containers/ 2>/dev/null
```

Also check for tools listed in the `Brewfile` that might have config:

```bash
grep -E '^brew |^cask ' Brewfile | awk '{print $2}' | tr -d '"'
```

For each tool with config, record: path, file count, total size, file modes.

## Step 2 — Classify each candidate

For every config location found, classify each file:

| Classification | Managed? | Examples |
|---------------|----------|----------|
| Portable config | Yes | settings.json, config.toml, .rc files with user preferences |
| Credential | Never | tokens, API keys, oauth files, hosts.yml with auth |
| Generated state | No | plugin installs, lock files, installer markers |
| Cache/database | No | .db, .sqlite, history, sessions, logs |
| Machine-specific | No | files with absolute paths that can't use `$HOME` |

**Credential detection** — grep for patterns, never print actual values:

```bash
grep -rli -E '(token|api_key|secret|password|oauth|credential|auth)' <path> 2>/dev/null
```

**Generated state detection** — look for:
- Files not present after a fresh install until the tool runs
- `node_modules/`, `__pycache__/`, `.cache/`
- Files with names like `*.lock`, `*.db`, `*.log`, `*.history`

## Step 3 — Filter out already-managed tools

Read the `PACKAGES` array from `link.sh` and remove those tools from the
candidate list. Also check `docs/research/` for tools that were previously
investigated — use prior findings as context, but re-evaluate rejected
candidates if the tool may have been upgraded or its config layout changed
since the last research snapshot.

## Step 4 — Assess symlink safety

For each remaining candidate, determine:

1. **Does the tool have a config redirect env var?** (e.g. `GH_CONFIG_DIR`,
   `ATUIN_CONFIG_DIR`). Check the tool's docs or `--help` output.

2. **Does the tool have a config-write command?** Something like
   `tool config set key value` that modifies the config file.

3. **Can the symlink test be run?** The established method from ADR 0009 (originally ADR 0004):
   create a scratch dir, symlink a config file into it, use the tool's own
   command to change a setting, verify the link survived. Use a side-effect-free
   write command and redirect all tool state (env vars, caches) into the scratch
   dir — see `/add-stow-package` Step 2 for the full isolated template.

Categorize each tool. For tools with **multiple writable files**, test each
file individually — a tool can write through one symlink and replace another.
Record per-file status in the research doc and only mark the tool as
"Verified safe" when every writable file passes:

| Safety status | Meaning |
|--------------|---------|
| Verified safe | Every writable file tested — all write through symlinks |
| Likely safe | Has a config command but not yet tested |
| Read-only / N/A | Config is never written by the tool — safe without a write-through test |
| Unknown | No config command or env var found, and tool may write to config |
| Partially safe | Some files write through, others don't — note which in the research doc |
| Unsafe | Known to replace symlinks |

## Step 5 — Determine package boundaries

For each viable candidate, specify:

- **Managed files** — exactly which files to track
- **Deliberately unmanaged** — what to exclude and why
- **Gitignore pattern** — the allowlist block needed (if any)
- **Permission notes** — which files are currently mode `600` and whether
  relaxing to `644` is acceptable (only if no credentials)

## Step 6 — Write the research document

Create `docs/research/NNNN-<slug>.md` (next sequential number after existing
research docs).

Follow the format established in `docs/research/0009-additional-stow-package-boundaries.md`:

```markdown
# <Title>

Research snapshot: <date> on macOS <version>.

## Executive conclusion

<2-3 sentences: how many candidates found, how many are ready to add>

## Inventory method

<What was scanned, how files were classified>

## Package boundaries

| Package | Managed files | Deliberately unmanaged |
| --- | --- | --- |

## Symlink safety

| Tool | Redirect variable | Write command | Status |
| --- | --- | --- | --- |

## <Any tool-specific sections needed>

<Detail for tools with unusual layouts, credential concerns, or portability issues>
```

## Step 7 — Summarize next steps

End the research doc with a clear action list:

**Ready to add** (symlink-safe, no credentials in managed files):
- `toolname` — manages `path/to/config`

**Needs investigation** (promising but unverified):
- `toolname` — needs symlink safety test, has config redirect via `ENV_VAR`

**Not viable** (unsafe or no portable config):
- `toolname` — reason

Then tell the user which candidates are ready for `/add-stow-package`.

## Step 8 — Commit

Commit the research document with the related work.

## Output

Report to the user:
1. How many candidates were found
2. How many are ready to add immediately
3. How many need further investigation
4. Anything surprising (unexpected credentials, large state directories, tools
   that replace symlinks)
