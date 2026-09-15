# delegate-skills Configuration Investigation

Research snapshot: 2026-09-15 on macOS 15.5.

## Executive conclusion

`~/.config/delegate-skills/config.json` is a portable, read-only configuration
file suitable for stow management. No credentials, no machine-specific paths,
no sensitive siblings.

## Inventory method

Inspected `~/.config/delegate-skills/` directory contents and file permissions.
Examined file content for credentials, tokens, and absolute paths.

## Findings

| File | Size | Mode | Classification |
|------|------|------|----------------|
| `.config/delegate-skills/config.json` | 372 | 644 | portable-config |

The directory contains only the config file. No generated state, credentials,
or caches.

### Content analysis

The file contains delegate-fleet lane configuration:

```json
{
  "version": "delegate-fleet.v1",
  "lanes": {
    "feature": { "implementer": "agy" },
    "tests": { "implementer": "agy", "model": "gemini-3.8-flash-medium" },
    ...
  }
}
```

No absolute paths, no tokens, no credentials.

### Symlink safety

No CLI tool modifies this file programmatically. It is read-only configuration
consumed by the delegate-fleet system. Write-through verification is not
required for read-only files.

### Gitignore

Not needed. The source directory contains only the managed file with no
sensitive siblings.
