#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_DIR
readonly TARGET_DIR="${HOME:?HOME must be set}"
readonly -a PACKAGES=(agents atuin claude codex gh git mise olink opencode ssh zed zsh)

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
    adopt_skill_lock
    run_stow
    ;;
  restow)
    adopt_skill_lock
    run_stow --restow
    ;;
  uninstall)
    run_stow --delete
    ;;
  *)
    echo "Usage: $0 {check|install|restow|uninstall}" >&2
    exit 2
    ;;
esac
