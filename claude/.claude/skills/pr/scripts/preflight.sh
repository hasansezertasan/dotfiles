#!/usr/bin/env bash
# Pre-flight report for the `pr` skill. Read-only: inspects, never mutates.
# Usage: preflight.sh
set -uo pipefail

CANON='^(feature|bugfix|hotfix|release|chore)/[a-z0-9]+(-[a-z0-9]+)*$'
# Segments carrying no information about the change: always wrong.
DEAD_WORDS='wip|tmp|temp|foo|bar|baz|stuff|misc|things|changes|update|updates|final|new|branch'
# Agent and tool names: wrong as authorship, fine as subject matter
# (feature/add-claude-global-config is about Claude, not authored-by-Claude),
# so these are surfaced for judgement rather than failed outright.
TOOL_WORDS='claude|anthropic|ai|bot|agent|copilot|cursor|codex|gpt|llm|orca'

say() { printf '%s\n' "$*"; }
kv()  { printf '%-18s %s\n' "$1" "$2"; }

git rev-parse --git-dir >/dev/null 2>&1 || { say "NOT A GIT REPO"; exit 1; }

branch=$(git branch --show-current)
[ -n "$branch" ] || { say "DETACHED HEAD - resolve before opening a PR"; exit 1; }

# Default branch: origin/HEAD, else main, else master.
default=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
if [ -z "$default" ]; then
  for c in main master; do
    git show-ref --verify --quiet "refs/heads/$c" && { default=$c; break; }
  done
fi
default=${default:-main}

say "=== BRANCH ==="
kv "current" "$branch"
kv "default" "$default"

on_origin=no
if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then on_origin=yes; fi
kv "on origin" "$on_origin"

if [ "$branch" = "$default" ]; then
  kv "verdict" "ON DEFAULT BRANCH - a new branch must be created"
elif printf '%s' "$branch" | grep -Eq "$CANON"; then
  kv "verdict" "CONFORMS"
else
  kv "verdict" "NON-CONFORMING - needs a conventional name"
fi

# Which segments look like a person or tool rather than the change?
gituser=$(git config user.name 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d ' ')
gitmail=$(git config user.email 2>/dev/null | cut -d@ -f1 | tr '[:upper:]' '[:lower:]')
bad=""; advise=""
IFS='/-' read -r -a segs <<< "$(printf '%s' "$branch" | tr '[:upper:]' '[:lower:]')"
for seg in "${segs[@]}"; do
  [ -n "$seg" ] || continue
  case " $bad $advise " in *" $seg("*) continue ;; esac
  if { [ -n "$gituser" ] && [ "$seg" = "$gituser" ]; } || { [ -n "$gitmail" ] && [ "$seg" = "$gitmail" ]; }; then
    bad="$bad $seg(username)"
  elif printf '%s' "$seg" | grep -Eq "^($DEAD_WORDS)$"; then
    bad="$bad $seg(no-information)"
  elif printf '%s' "$seg" | grep -Eq "^($TOOL_WORDS)$"; then
    advise="$advise $seg"
  fi
done
[ -n "$bad" ] && kv "banned segments" "$bad"
[ -n "$advise" ] && kv "judge these" "$advise - authorship (rename) or subject matter (keep)?"

say ""
say "=== UNPUSHED COMMITS ==="
range="$default..HEAD"
if [ "$on_origin" = yes ]; then range="origin/$branch..HEAD"; fi
count=$(git rev-list --count "$range" 2>/dev/null || echo 0)
kv "range" "$range"
kv "count" "$count"
if [ "$count" != 0 ]; then
  CC='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._/-]+\))?!?: .+'
  while IFS= read -r line; do
    sha=${line%% *}; subj=${line#* }
    if printf '%s' "$subj" | grep -Eq "$CC"; then mark=ok; else mark="NON-CONVENTIONAL"; fi
    printf '  %s  %-16s %s\n' "$sha" "$mark" "$subj"
  done < <(git log --reverse --format='%h %s' "$range")
fi

say ""
say "=== AI ATTRIBUTION IN UNPUSHED COMMITS ==="
if [ "$count" != 0 ] && git log --format='%B' "$range" \
     | grep -Eni '^[[:space:]]*co-authored-by:.*(claude|anthropic)|generated with \[?claude|🤖' ; then
  say "  ^ must be stripped before pushing"
else
  say "  none"
fi

say ""
say "=== EXISTING PR ==="
if command -v gh >/dev/null 2>&1; then
  pr=$(gh pr view "$branch" --json number,state,title,url 2>/dev/null)
  if [ -n "$pr" ]; then say "  $pr"; else say "  none open for $branch"; fi
else
  say "  gh not installed"
fi

say ""
say "=== WORKING TREE ==="
git status --short
say ""
kv "tracked edits" "$(git diff HEAD --name-only | wc -l | tr -d ' ')"
kv "untracked files" "$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')"
git diff HEAD --stat | tail -1
