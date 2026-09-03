#!/usr/bin/env bash
# Pre-flight report for the `pr` skill. Read-only: inspects, never mutates.
# Usage: preflight.sh [--local]
set -uo pipefail

CONVENTIONAL_BRANCH_RE='^(feature|bugfix|hotfix|release|chore)/[a-z0-9]+(-[a-z0-9]+)*$'
# Segments carrying no information about the change: always wrong.
DEAD_WORDS='wip|tmp|temp|foo|bar|baz|stuff|misc|things|changes|update|updates|final|new|branch|test'
# Agent and tool names: wrong as authorship, fine as subject matter
# (feature/add-claude-global-config is about Claude, not authored-by-Claude),
# so these are surfaced for judgement rather than failed outright.
TOOL_WORDS='claude|anthropic|ai|bot|agent|copilot|cursor|codex|gpt|llm|orca'

say() { printf '%s\n' "$*"; }
kv()  { printf '%-18s %s\n' "$1" "$2"; }
normalize() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-//; s/-$//'
}
resolve_remote_branch_sha() {
  local remote_ref output status
  remote_ref="refs/heads/$1"
  output=$(git ls-remote --exit-code --heads origin "$remote_ref" 2>/dev/null)
  status=$?
  [ "$status" -eq 0 ] || return "$status"
  printf '%s\n' "$output" \
    | awk -v expected="$remote_ref" '$2 == expected { print $1; found = 1; exit } END { if (!found) exit 2 }'
}

git rev-parse --git-dir >/dev/null 2>&1 || { say "NOT A GIT REPO"; exit 1; }

local_only=no
case "${1:-}" in
  --local) local_only=yes ;;
  "") ;;
  *) say "Usage: preflight.sh [--local]"; exit 2 ;;
esac

branch=$(git branch --show-current)
[ -n "$branch" ] || { say "DETACHED HEAD - resolve before opening a PR"; exit 1; }

# Query origin in full mode so a stale local origin/HEAD cannot select the wrong base.
if [ "$local_only" = yes ]; then
  default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
  default=${default:-unknown}
else
  remote_head=$(git ls-remote --symref origin HEAD 2>/dev/null)
  remote_head_status=$?
  if [ "$remote_head_status" -eq 0 ]; then
    default=$(printf '%s\n' "$remote_head" | awk '$1 == "ref:" && $3 == "HEAD" { sub("refs/heads/", "", $2); print $2; exit }')
  fi
  if [ "$remote_head_status" -ne 0 ] || [ -z "$default" ]; then
    say "DEFAULT BRANCH UNKNOWN - could not resolve origin/HEAD"
    exit 1
  fi
fi

say "=== BRANCH ==="
kv "current" "$branch"
kv "default" "$default"

if [ "$local_only" = yes ]; then
  on_origin=unknown
  remote_branch_sha=""
  kv "on origin" "UNKNOWN - local-only mode"
else
  remote_branch=$(resolve_remote_branch_sha "$branch")
  remote_status=$?
  case "$remote_status" in
    0)
      on_origin=yes
      remote_branch_sha="$remote_branch"
      ;;
    2)
      on_origin=no
      remote_branch_sha=""
      ;;
    *)
      kv "on origin" "UNKNOWN - remote lookup failed"
      exit 1
      ;;
  esac
  kv "on origin" "$on_origin"
fi

# Which segments look like a person or tool rather than the change?
normalized_branch=$(normalize "$branch")
gituser=$(normalize "$(git config user.name 2>/dev/null)")
gitmail=$(normalize "$(git config user.email 2>/dev/null | cut -d@ -f1)")
bad=""; advise=""
for identity in "$gituser" "$gitmail"; do
  [ -n "$identity" ] || continue
  case "-$normalized_branch-" in
    *-"$identity"-*)
      case " $bad " in *" $identity(username) "*) ;; *) bad="$bad $identity(username)" ;; esac
      ;;
  esac
done
IFS='-' read -r -a segs <<< "$normalized_branch"
for seg in "${segs[@]}"; do
  [ -n "$seg" ] || continue
  case " $bad $advise " in *" $seg("*) continue ;; esac
  if printf '%s' "$seg" | grep -Eq "^($DEAD_WORDS)$"; then
    bad="$bad $seg(no-information)"
  elif printf '%s' "$seg" | grep -Eq "^($TOOL_WORDS)$"; then
    advise="$advise $seg"
  fi
done
branch_description=${normalized_branch#*-}
if printf '%s' "$branch_description" | grep -Eq '^([0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{8})$'; then
  bad="$bad $branch_description(bare-date)"
fi
[ -n "$bad" ] && kv "banned segments" "$bad"
[ -n "$advise" ] && kv "judge these" "$advise - authorship (rename) or subject matter (keep)?"

if [ "$branch" = "$default" ]; then
  kv "verdict" "ON DEFAULT BRANCH - a new branch must be created"
elif ! printf '%s' "$branch" | grep -Eq "$CONVENTIONAL_BRANCH_RE" || [ -n "$bad" ]; then
  kv "verdict" "NON-CONFORMING - needs a conventional name"
else
  kv "verdict" "CONFORMS"
fi

if [ "$local_only" = no ]; then
  say ""
  say "=== UNPUSHED COMMITS ==="
  if [ "$on_origin" = yes ]; then
    base="$remote_branch_sha"
    base_label="origin/$branch"
  else
    remote_default=$(resolve_remote_branch_sha "$default")
    remote_default_status=$?
    if [ "$remote_default_status" -ne 0 ]; then
      say "UNPUSHED RANGE UNKNOWN - could not resolve origin/$default"
      exit 1
    fi
    base="$remote_default"
    base_label="origin/$default"
  fi
  if ! git rev-parse --verify --quiet "$base^{commit}" >/dev/null; then
    say "UNPUSHED RANGE UNKNOWN - fetch $base_label before continuing"
    exit 1
  fi
  range="$base..HEAD"
  if ! count=$(git rev-list --count "$range" 2>/dev/null); then
    say "UNPUSHED RANGE UNKNOWN - could not resolve $range"
    exit 1
  fi
  kv "range" "$range"
  kv "count" "$count"
  if [ "$on_origin" = yes ]; then
    if ! remote_only=$(git rev-list --count "HEAD..$base" 2>/dev/null); then
      say "REMOTE RANGE UNKNOWN - could not resolve HEAD..$base"
      exit 1
    fi
    kv "remote-only" "$remote_only"
    if [ "$remote_only" != 0 ]; then
      say "REMOTE AHEAD - fetch and reconcile $base_label before continuing"
      exit 1
    fi
  fi
  if [ "$count" != 0 ]; then
    CONVENTIONAL_COMMIT_RE='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._/-]+\))?!?: .+'
    while IFS= read -r line; do
      sha=${line%% *}; subj=${line#* }
      if printf '%s' "$subj" | grep -Eq "$CONVENTIONAL_COMMIT_RE"; then mark=ok; else mark="NON-CONVENTIONAL"; fi
      printf '  %s  %-16s %s\n' "$sha" "$mark" "$subj"
    done < <(git log --reverse --format='%h %s' "$range")
  fi

  say ""
  say "=== AI ATTRIBUTION IN UNPUSHED COMMITS ==="
  if [ "$count" != 0 ] && git log --format='%B' "$range" \
       | grep -Eni "^[[:space:]]*co-authored-by:.*[^[:alnum:]]($TOOL_WORDS)([^[:alnum:]]|$)|generated[[:space:]]+(with|by).*[^[:alnum:]]($TOOL_WORDS)([^[:alnum:]]|$)|🤖" ; then
    say "  ^ must be stripped before pushing"
  else
    say "  none"
  fi

  say ""
  say "=== EXISTING PR ==="
  if command -v gh >/dev/null 2>&1; then
    repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)
    if ! printf '%s' "$repo" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'; then
      say "  UNKNOWN - current GitHub repository lookup failed"
      exit 1
    fi
    if pr=$(gh pr list --head "$branch" --state open --limit 100 \
        --json number,state,title,url,headRepository \
        --jq "[.[] | select(.headRepository.nameWithOwner == \"$repo\")][0] // empty" 2>/dev/null); then
      if [ -n "$pr" ]; then say "  $pr"; else say "  none open for $branch"; fi
    else
      say "  UNKNOWN - PR lookup failed"
      exit 1
    fi
  else
    say "  GH CLI REQUIRED - install and authenticate gh before opening a PR"
    exit 1
  fi
else
  say ""
  say "=== REMOTE CHECKS ==="
  say "  skipped in local-only mode"
fi

say ""
say "=== WORKING TREE ==="
git status --short
say ""
kv "tracked edits" "$(git diff HEAD --name-only | wc -l | tr -d ' ')"
kv "untracked files" "$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')"
git diff HEAD --stat | tail -1
