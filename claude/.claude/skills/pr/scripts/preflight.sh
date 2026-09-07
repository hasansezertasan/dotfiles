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
TOOL_WORDS='claude|anthropic|ai|bot|agent|copilot|cursor|codex|chatgpt|openai|gpt|llm'

say() { printf '%s\n' "$*"; }
kv()  { printf '%-18s %s\n' "$1" "$2"; }
matches() { printf '%s' "$1" | grep -Eq "$2"; }
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
[ "$#" -le 1 ] || { say "Usage: preflight.sh [--local]"; exit 2; }
case "${1:-}" in
  --local) local_only=yes ;;
  "") ;;
  *) say "Usage: preflight.sh [--local]"; exit 2 ;;
esac

branch=$(git branch --show-current)
[ -n "$branch" ] || { say "DETACHED HEAD - resolve before opening a PR"; exit 1; }

if [ "$local_only" = yes ]; then
  default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
  default=${default:-unknown}
  on_origin=unknown
  remote_branch_sha=""
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
fi

say "=== BRANCH ==="
kv "current" "$branch"
kv "default" "$default"
if [ "$local_only" = yes ]; then
  kv "on origin" "UNKNOWN - local-only mode"
else
  kv "on origin" "$on_origin"
fi

# Which segments look like a person or tool rather than the change?
normalized_branch=$(normalize "$branch")
gituser=$(normalize "$(git config user.name 2>/dev/null)")
raw_email=$(git config user.email 2>/dev/null)
raw_local=${raw_email%%@*}
gitmail=$(normalize "$raw_local")
gitnoreply=""
case "$raw_email" in
  *+*@users.noreply.github.com) gitnoreply=$(normalize "${raw_local#*+}") ;;
esac
normalized_desc=$(normalize "${branch#*/}")
bad=""; advise=""
for identity in "$gituser" "$gitmail" "$gitnoreply"; do
  [ -n "$identity" ] || continue
  case "-$normalized_desc-" in
    *-"$identity"-*)
      case " $bad " in *" $identity(username) "*) ;; *) bad="$bad $identity(username)" ;; esac
      ;;
  esac
done
IFS='-' read -r -a segs <<< "$normalized_branch"
for seg in "${segs[@]}"; do
  [ -n "$seg" ] || continue
  case " $bad $advise " in *" $seg("*) continue ;; esac
  # Dead words are only vague when they ARE the entire description;
  # in a compound like add-test-coverage, "test" is informative.
  if matches "$seg" "^($DEAD_WORDS)$" && [ "$normalized_desc" = "$seg" ]; then
    bad="$bad $seg(no-information)"
  elif matches "$seg" "^($TOOL_WORDS)$"; then
    advise="$advise $seg"
  fi
done
branch_description=${normalized_branch#*-}
if matches "$branch_description" '^([0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{8})$'; then
  bad="$bad $branch_description(bare-date)"
fi
[ -n "$bad" ] && kv "banned segments" "$bad"
[ -n "$advise" ] && kv "judge these" "$advise - authorship (rename) or subject matter (keep)?"

if [ "$branch" = "$default" ]; then
  kv "verdict" "ON DEFAULT BRANCH - a new branch must be created"
elif ! matches "$branch" "$CONVENTIONAL_BRANCH_RE" || [ -n "$bad" ]; then
  kv "verdict" "NON-CONFORMING - needs a conventional name"
else
  kv "verdict" "CONFORMS"
fi

has_head=yes
git rev-parse --verify --quiet HEAD >/dev/null 2>&1 || has_head=no

if [ "$local_only" = no ] && [ "$has_head" = yes ]; then
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
  if ! git merge-base --is-ancestor "$base" HEAD 2>/dev/null \
     && ! git merge-base --is-ancestor HEAD "$base" 2>/dev/null \
     && ! git merge-base "$base" HEAD >/dev/null 2>&1; then
    if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
      say "SHALLOW CLONE - deepen or unshallow before opening a PR"
    else
      say "UNRELATED HISTORIES - HEAD and $base_label share no ancestor"
    fi
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
      if matches "$subj" "$CONVENTIONAL_COMMIT_RE" && ! matches "$subj" '\.$'; then mark=ok; else mark="NON-CONVENTIONAL"; fi
      printf '  %s  %-16s %s\n' "$sha" "$mark" "$subj"
    done < <(git log --reverse --format='%h %s' "$range")
  fi

  say ""
  say "=== AI ATTRIBUTION IN UNPUSHED COMMITS ==="
  ATTR_RE="^[[:space:]]*co-authored-by[[:space:]]*:[[:space:]]*(($TOOL_WORDS)([^[:alnum:]]|$)|[^<]*[^[:alnum:]<]($TOOL_WORDS)([^[:alnum:]]|$))|generated[[:space:]]+(with|by)[^<]*[^[:alnum:]<]($TOOL_WORDS)([^[:alnum:]]|$)|^[[:space:]]*🤖"
  attr_found=no
  if [ "$count" != 0 ]; then
    while IFS= read -r sha; do
      if git log -1 --format='%B' "$sha" | grep -Eqi "$ATTR_RE"; then
        printf '  %s  ATTRIBUTION\n' "$sha"
        attr_found=yes
      fi
    done < <(git log --reverse --format='%h' "$range")
  fi
  if [ "$attr_found" = yes ]; then
    say "  ^ must be stripped before pushing"
  else
    say "  none"
  fi

  say ""
  say "=== EXISTING PR ==="
  if command -v gh >/dev/null 2>&1; then
    repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)
    if ! matches "$repo" '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$'; then
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
elif [ "$has_head" = no ] && [ "$local_only" = no ]; then
  say ""
  say "NO COMMITS YET - commit before opening a PR"
  exit 1
elif [ "$has_head" = no ]; then
  say ""
  say "=== UNPUSHED COMMITS ==="
  say "  skipped - no commits yet"
else
  say ""
  say "=== REMOTE CHECKS ==="
  say "  skipped in local-only mode"
fi

say ""
say "=== WORKING TREE ==="
git status --short
say ""
if [ "$has_head" = yes ]; then
  kv "tracked edits" "$(git diff HEAD --name-only | wc -l | tr -d ' ')"
  kv "untracked files" "$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')"
  git diff HEAD --stat | tail -1
else
  kv "tracked edits" "n/a (no commits yet)"
  kv "untracked files" "$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')"
fi
