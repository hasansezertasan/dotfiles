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
TOOL_WORDS='claude|anthropic|ai|bot|agent|copilot|cursor|codex|chatgpt|openai|gpt|llm'

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

# --- dead words (regex match) ---
assert "wip is dead"          matches "wip"    "^($DEAD_WORDS)$"
assert "tmp is dead"          matches "tmp"    "^($DEAD_WORDS)$"
assert "misc is dead"         matches "misc"   "^($DEAD_WORDS)$"
refute "login is not dead"    matches "login"  "^($DEAD_WORDS)$"
refute "widget is not dead"   matches "widget" "^($DEAD_WORDS)$"

# --- dead words only flag when they ARE the entire description ---
normalize() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-//; s/-$//'
}
is_sole_desc() { local branch=$1 seg=$2; local desc; desc=$(normalize "${branch#*/}"); [ "$desc" = "$seg" ]; }
assert "chore/wip: wip is sole desc"                   is_sole_desc "chore/wip" "wip"
refute "feature/add-test-coverage: test not sole desc"  is_sole_desc "feature/add-test-coverage" "test"
refute "chore/update-dependencies: update not sole"     is_sole_desc "chore/update-dependencies" "update"
refute "feature/new-auth-flow: new not sole"            is_sole_desc "feature/new-auth-flow" "new"

# --- noreply handle extraction (GitHub noreply only) ---
extract_noreply() {
  local email=$1 local_part=${1%%@*}
  case "$email" in *+*@users.noreply.github.com) normalize "${local_part#*+}" ;; *) return 1 ;; esac
}
assert "github noreply yields handle"  test "$(extract_noreply '13135006+hasansezertasan@users.noreply.github.com')" = "hasansezertasan"
refute "plain email has no handle"     extract_noreply "hasansezertasan@gmail.com"
refute "non-github plus-addr skipped"  extract_noreply "john+work@gmail.com"

# --- tool words ---
assert "claude is tool"       matches "claude"    "^($TOOL_WORDS)$"
assert "ai is tool"           matches "ai"        "^($TOOL_WORDS)$"
assert "copilot is tool"      matches "copilot"   "^($TOOL_WORDS)$"
assert "chatgpt is tool"     matches "chatgpt"   "^($TOOL_WORDS)$"
assert "openai is tool"      matches "openai"    "^($TOOL_WORDS)$"
refute "react is not tool"    matches "react"     "^($TOOL_WORDS)$"
refute "orca is not tool"     matches "orca"      "^($TOOL_WORDS)$"

# --- commit subjects (two-part check mirrors preflight.sh) ---
CONVENTIONAL_COMMIT_RE='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._/-]+\))?!?: .+'
commit_ok() { matches "$1" "$CONVENTIONAL_COMMIT_RE" && ! matches "$1" '\.$'; }
assert "feat: add login"                commit_ok "feat: add login"
assert "fix(auth): handle null"         commit_ok "fix(auth): handle null"
assert "feat!: breaking change"         commit_ok "feat!: breaking change"
assert "fix: x (single char desc)"      commit_ok "fix: x"
refute "trailing period rejected"       commit_ok "feat: add login."
refute "missing type rejected"          commit_ok "add login"
refute "uppercase type rejected"        commit_ok "Feat: add login"

# --- bare dates ---
BARE_DATE_RE='^([0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{8})$'
assert "2026-09-07 is bare date"  matches "2026-09-07" "$BARE_DATE_RE"
assert "20260907 is bare date"    matches "20260907"    "$BARE_DATE_RE"
refute "add-login not a date"     matches "add-login"   "$BARE_DATE_RE"
refute "2026 not a full date"     matches "2026"        "$BARE_DATE_RE"

# --- attribution detection (tool name in name vs email domain) ---
ATTR_RE="^[[:space:]]*co-authored-by[[:space:]]*:[[:space:]]*(($TOOL_WORDS)([^[:alnum:]]|$)|[^<]*[^[:alnum:]<]($TOOL_WORDS)([^[:alnum:]]|$))|generated[[:space:]]+(with|by)[^<]*[^[:alnum:]<]($TOOL_WORDS)([^[:alnum:]]|$)|^[[:space:]]*🤖"
attr() { printf '%s' "$1" | grep -Eqi "$ATTR_RE"; }
assert "co-authored claude bot"         attr "Co-authored-by: Claude Bot <noreply@anthropic.com>"
assert "co-authored chatgpt"            attr "Co-authored-by: ChatGPT <chatgpt@openai.com>"
assert "generated with claude"          attr "Generated with Claude"
assert "space before colon"             attr "Co-authored-by : Claude <x@y>"
assert "no space after colon"           attr "Co-authored-by:Claude <x@y>"
assert "robot emoji at line start"      attr "🤖 Generated with Claude Code"
refute "robot emoji mid-subject"        attr "feat: add 🤖 status icon"
refute "human with .ai domain"          attr "Co-authored-by: Alice Example <ai@example.com>"
refute "human with claude.com domain"   attr "Co-authored-by: Jane <jane@claude.com>"
refute "generated by human with .ai"    attr "Generated by Jane <jane@company.ai>"

echo ""
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
