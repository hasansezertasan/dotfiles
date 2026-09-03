#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_DIR
readonly TARGET_DIR="${HOME:?HOME must be set}"
readonly -a PACKAGES=(atuin claude codex gh git mise olink opencode ssh zed zsh)

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

case "${1:-}" in
  check)
    run_stow --simulate --verbose=2
    ;;
  install)
    run_stow
    ;;
  restow)
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
