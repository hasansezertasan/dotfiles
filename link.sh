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

codex_hook_link_is_stale() {
  [ -L "${CODEX_HOOK_LINK}" ] || return 1
  # The package is gone, so a link into it dangles; that alone identifies it.
  [ -e "${CODEX_HOOK_LINK}" ] || return 0
  local resolved
  resolved="$(
    cd -- "$(dirname -- "${CODEX_HOOK_LINK}")" || exit 1
    cd -- "$(dirname -- "$(readlink -- "${CODEX_HOOK_LINK}")")" || exit 1
    pwd -P
  )" || return 1
  [ "${resolved}" = "${DOTFILES_DIR}/codex/.codex" ]
}

drop_stale_codex_hook_link() {
  if codex_hook_link_is_stale; then
    rm -- "${CODEX_HOOK_LINK}"
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
