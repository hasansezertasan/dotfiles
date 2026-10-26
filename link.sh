#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_DIR
readonly TARGET_DIR="${HOME:?HOME must be set}"
readonly -a PACKAGES=(agents atuin claude codex delegate-skills gh git mise olink opencode pi ssh zed zsh)

if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow is required. Install it with: brew install stow" >&2
  exit 1
fi

run_stow() {
  stow \
    --dir="${DOTFILES_DIR}" \
    --target="${TARGET_DIR}" \
    --no-folding \
    "$@" \
    "${PACKAGES[@]}"
}

run_agents_stow() {
  stow \
    --dir="${DOTFILES_DIR}" \
    --target="${TARGET_DIR}" \
    --no-folding \
    "$@" \
    agents
}

run_non_agents_stow() {
  stow \
    --dir="${DOTFILES_DIR}" \
    --target="${TARGET_DIR}" \
    --no-folding \
    "$@" \
    "${PACKAGES[@]:1}"
}

skill_lock_needs_adoption() {
  local skill_lock="${TARGET_DIR}/.agents/.skill-lock.json"
  [ -f "${skill_lock}" ] && [ ! -L "${skill_lock}" ]
}

adopt_skill_lock() {
  if skill_lock_needs_adoption; then
    run_agents_stow --adopt
  fi
}

preflight_non_agents() {
  run_non_agents_stow --simulate "$@"
}

# ADR 0017 removed the codex package. A machine linked by an earlier revision
# still has ~/.codex/hooks.json pointing at the deleted target, and Stow is no
# longer told about the package, so it never cleans that link up. Codex writing
# through the dangling link would recreate the file inside this repository.
readonly CODEX_HOOK_LINK="${TARGET_DIR}/.codex/hooks.json"
readonly CODEX_HOOK_FORMER_TARGET="${DOTFILES_DIR}/codex/.codex/hooks.json"

# Resolve '.' and '..' textually. The former target no longer exists, so the
# link cannot be resolved by cd-ing to it, and a dangling link alone must not
# be taken as evidence: another tool may own an unrelated one.
lexical_path() {
  local input="$1" part
  local -a parts=() raw=()
  local old_ifs="${IFS}"
  IFS='/'
  # shellcheck disable=SC2206 # splitting on path separators is the point
  raw=(${input})
  IFS="${old_ifs}"
  for part in ${raw[@]+"${raw[@]}"}; do
    case "${part}" in
      '' | .) ;;
      ..)
        if [ "${#parts[@]}" -gt 0 ]; then
          parts=(${parts[@]+"${parts[@]:0:$((${#parts[@]} - 1))}"})
        fi
        ;;
      *) parts+=("${part}") ;;
    esac
  done
  local resolved=""
  for part in ${parts[@]+"${parts[@]}"}; do
    resolved="${resolved}/${part}"
  done
  printf '%s\n' "${resolved:-/}"
}

codex_hook_link_target() {
  local value
  value="$(readlink -- "${CODEX_HOOK_LINK}")"
  case "${value}" in
    /*) lexical_path "${value}" ;;
    *) lexical_path "$(dirname -- "${CODEX_HOOK_LINK}")/${value}" ;;
  esac
}

codex_hook_link_is_stale() {
  [ -L "${CODEX_HOOK_LINK}" ] || return 1
  [ "$(codex_hook_link_target)" = "$(lexical_path "${CODEX_HOOK_FORMER_TARGET}")" ]
}

drop_stale_codex_hook_link() {  codex_hook_link_is_stale || return 0
  local target
  target="$(codex_hook_link_target)"
  rm -- "${CODEX_HOOK_LINK}"
  if [ -f "${target}" ]; then
    # Codex wrote through the stale link before this ran, recreating the file
    # inside the repository. Keep that content in the home directory, where
    # Codex expects it, and leave nothing behind in the repository.
    mv -- "${target}" "${CODEX_HOOK_LINK}"
    rmdir -- "$(dirname -- "${target}")" 2>/dev/null || :
    rmdir -- "$(dirname -- "$(dirname -- "${target}")")" 2>/dev/null || :
  fi
}

# ADR 0020 removed the vendored pr skill from the claude package. A machine
# linked by an earlier revision still has ~/.claude/skills/pr/... links
# pointing at the deleted files, and Stow is no longer told about them, so it
# never cleans those links up. Skill files are only read, so unlike the Codex
# hook there is no write-through content to recover — dropping the stale
# links and any directories left empty is enough.
readonly -a PR_SKILL_FORMER_FILES=(
  .claude/skills/pr/SKILL.md
  .claude/skills/pr/scripts/preflight.sh
  .claude/skills/pr/scripts/test_preflight.sh
)

pr_skill_link_is_stale() {
  local link="$1" former="$2" value target
  [ -L "${link}" ] || return 1
  value="$(readlink -- "${link}")"
  case "${value}" in
    /*) target="$(lexical_path "${value}")" ;;
    *) target="$(lexical_path "$(dirname -- "${link}")/${value}")" ;;
  esac
  [ "${target}" = "$(lexical_path "${former}")" ]
}

drop_stale_pr_skill_links() {
  local rel link former
  for rel in ${PR_SKILL_FORMER_FILES[@]+"${PR_SKILL_FORMER_FILES[@]}"}; do
    link="${TARGET_DIR}/${rel}"
    former="${DOTFILES_DIR}/claude/${rel}"
    pr_skill_link_is_stale "${link}" "${former}" || continue
    rm -- "${link}"
  done
  # rmdir only removes empty directories, so unrelated content is safe.
  rmdir -- "${TARGET_DIR}/.claude/skills/pr/scripts" 2>/dev/null || :
  rmdir -- "${TARGET_DIR}/.claude/skills/pr" 2>/dev/null || :
}

case "${1:-}" in
  check)
    if skill_lock_needs_adoption; then
      run_agents_stow --simulate --verbose=2 --adopt
      run_non_agents_stow --simulate --verbose=2
    else
      run_stow --simulate --verbose=2
    fi
    ;;
  install)
    if skill_lock_needs_adoption; then
      preflight_non_agents
    fi
    drop_stale_codex_hook_link
    drop_stale_pr_skill_links
    adopt_skill_lock
    run_stow
    ;;
  restow)
    if skill_lock_needs_adoption; then
      preflight_non_agents --restow
    fi
    drop_stale_codex_hook_link
    drop_stale_pr_skill_links
    adopt_skill_lock
    run_stow --restow
    ;;
  uninstall)
    drop_stale_codex_hook_link
    drop_stale_pr_skill_links
    run_stow --delete
    ;;
  *)
    echo "Usage: $0 {check|install|restow|uninstall}" >&2
    exit 2
    ;;
esac
