#!/usr/bin/env bash
# Smoke tests for preflight.sh regex helpers.
# Run: bash scripts/test_preflight.sh
set -uo pipefail

pass=0 fail=0
assert() {
  local label=$1; shift
  if "$@" >/dev/null 2>&1; then
    ((pass++))
  else
    echo "FAIL: $label"
    ((fail++))
  fi
}
refute() {
  local label=$1; shift
  if ! "$@" >/dev/null 2>&1; then
    ((pass++))
  else
    echo "FAIL (expected reject): $label"
    ((fail++))
  fi
}

CONVENTIONAL_BRANCH_RE='^(feature|bugfix|hotfix|release|chore)/[a-z0-9]+(-[a-z0-9]+)*$'
DEAD_WORDS='wip|tmp|temp|foo|bar|baz|stuff|misc|things|changes|update|updates|final|new|branch|test'
TOOL_WORDS='claude|anthropic|ai|bot|agent|copilot|cursor|codex|gpt|llm'

matches() { printf '%s' "$1" | grep -Eq "$2"; }

# --- branch conformance ---
assert "feature/add-login conforms"       matches "feature/add-login"       "$CONVENTIONAL_BRANCH_RE"
assert "bugfix/fix-null-ptr conforms"     matches "bugfix/fix-null-ptr"     "$CONVENTIONAL_BRANCH_RE"
assert "hotfix/urgent-patch conforms"     matches "hotfix/urgent-patch"     "$CONVENTIONAL_BRANCH_RE"
assert "release/1-0-0 conforms"           matches "release/1-0-0"           "$CONVENTIONAL_BRANCH_RE"
assert "chore/bump-deps conforms"         matches "chore/bump-deps"         "$CONVENTIONAL_BRANCH_RE"
refute "main rejected"                    matches "main"                    "$CONVENTIONAL_BRANCH_RE"
refute "Feature/Add-Login rejected"       matches "Feature/Add-Login"       "$CONVENTIONAL_BRANCH_RE"
refute "feature/add_login rejected"       matches "feature/add_login"       "$CONVENTIONAL_BRANCH_RE"
refute "feat/add-login rejected"          matches "feat/add-login"          "$CONVENTIONAL_BRANCH_RE"
refute "feature/ rejected (empty desc)"   matches "feature/"                "$CONVENTIONAL_BRANCH_RE"
refute "feature/add-login- rejected"      matches "feature/add-login-"      "$CONVENTIONAL_BRANCH_RE"

# --- dead words ---
assert "wip is dead"          matches "wip"    "^($DEAD_WORDS)$"
assert "tmp is dead"          matches "tmp"    "^($DEAD_WORDS)$"
assert "misc is dead"         matches "misc"   "^($DEAD_WORDS)$"
refute "login is not dead"    matches "login"  "^($DEAD_WORDS)$"
refute "widget is not dead"   matches "widget" "^($DEAD_WORDS)$"

# --- tool words ---
assert "claude is tool"       matches "claude"    "^($TOOL_WORDS)$"
assert "ai is tool"           matches "ai"        "^($TOOL_WORDS)$"
assert "copilot is tool"      matches "copilot"   "^($TOOL_WORDS)$"
refute "react is not tool"    matches "react"     "^($TOOL_WORDS)$"
refute "orca is not tool"     matches "orca"      "^($TOOL_WORDS)$"

# --- bare dates ---
BARE_DATE_RE='^([0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{8})$'
assert "2026-09-07 is bare date"  matches "2026-09-07" "$BARE_DATE_RE"
assert "20260907 is bare date"    matches "20260907"    "$BARE_DATE_RE"
refute "add-login not a date"     matches "add-login"   "$BARE_DATE_RE"
refute "2026 not a full date"     matches "2026"        "$BARE_DATE_RE"

echo ""
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
