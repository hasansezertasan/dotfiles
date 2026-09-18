#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_DIR
readonly TARGET_DIR="${HOME:?HOME must be set}"
readonly -a PACKAGES=(agents atuin claude delegate-skills gh git mise olink opencode ssh zed zsh)

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

drop_stale_codex_hook_link() {
  codex_hook_link_is_stale || return 0
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
    adopt_skill_lock
    run_stow
    ;;
  restow)
    if skill_lock_needs_adoption; then
      preflight_non_agents --restow
    fi
    drop_stale_codex_hook_link
    adopt_skill_lock
    run_stow --restow
    ;;
  uninstall)
    drop_stale_codex_hook_link
    run_stow --delete
    ;;
  *)
    echo "Usage: $0 {check|install|restow|uninstall}" >&2
    exit 2
    ;;
esac
