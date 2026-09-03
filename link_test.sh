#!/usr/bin/env bash

# Behavioural test for link.sh. Every operation runs against a scratch HOME, so
# the real home directory is never touched.

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_DIR

# Paths the packages are expected to place in the target directory.
readonly -a EXPECTED_LINKS=(
  .claude/CLAUDE.md
  .config/atuin/config.toml
  .config/gh/config.yml
  .config/mise/config.toml
  .config/zsh/conf.d/00-path.zsh
  .config/zsh/conf.d/10-oh-my-zsh.zsh
  .gitconfig
  .zshrc
)

# --no-folding must leave these as real directories so applications can keep
# their own state alongside the managed files.
readonly -a EXPECTED_DIRS=(
  .claude
  .config
  .config/atuin
  .config/gh
  .config/mise
  .config/zsh
  .config/zsh/conf.d
)

failures=0

fail() {
  printf '  FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

# Resolve a symlink without readlink -f, which is not portable to macOS.
resolve_link() {
  local link="$1" value
  value="$(readlink -- "${link}")"
  (
    cd -- "$(dirname -- "${link}")" || exit 1
    cd -- "$(dirname -- "${value}")" || exit 1
    printf '%s/%s\n' "$(pwd -P)" "$(basename -- "${value}")"
  )
}

make_home() {
  mktemp -d "${TMPDIR:-/tmp}/link-test.XXXXXX"
}

run_link() {
  local home="$1"
  shift
  HOME="${home}" "${DOTFILES_DIR}/link.sh" "$@"
}

test_install_creates_expected_links() {
  echo "install creates every expected link, pointing into the repository"
  local home
  home="$(make_home)"

  run_link "${home}" install > /dev/null

  local link target resolved
  for link in "${EXPECTED_LINKS[@]}"; do
    target="${home}/${link}"
    if [ ! -L "${target}" ]; then
      fail "${link} is not a symlink"
      continue
    fi
    if [ ! -e "${target}" ]; then
      fail "${link} is a broken symlink"
      continue
    fi
    resolved="$(resolve_link "${target}")"
    case "${resolved}" in
      "${DOTFILES_DIR}/"*) ;;
      *) fail "${link} resolves outside the repository: ${resolved}" ;;
    esac
  done

  rm -rf "${home}"
}

test_shared_directories_are_not_links() {
  echo "--no-folding leaves shared directories as real directories"
  local home
  home="$(make_home)"

  run_link "${home}" install > /dev/null

  local dir target
  for dir in "${EXPECTED_DIRS[@]}"; do
    target="${home}/${dir}"
    if [ -L "${target}" ]; then
      fail "${dir} is a symlink; folding was not disabled"
    elif [ ! -d "${target}" ]; then
      fail "${dir} is not a directory"
    fi
  done

  rm -rf "${home}"
}

test_uninstall_removes_every_link() {
  echo "uninstall removes every link it created"
  local home
  home="$(make_home)"

  run_link "${home}" install > /dev/null
  run_link "${home}" uninstall > /dev/null

  local remaining
  remaining="$(find "${home}" -type l | wc -l | tr -d ' ')"
  if [ "${remaining}" -ne 0 ]; then
    fail "${remaining} link(s) survived uninstall"
  fi

  rm -rf "${home}"
}

test_conflict_is_refused() {
  echo "an existing file is refused, not overwritten or partially applied"
  local home
  home="$(make_home)"

  local existing="original contents"
  printf '%s\n' "${existing}" > "${home}/.gitconfig"

  if run_link "${home}" check > /dev/null 2>&1; then
    fail "check succeeded despite a conflicting target"
  fi
  if run_link "${home}" install > /dev/null 2>&1; then
    fail "install succeeded despite a conflicting target"
  fi

  if [ -L "${home}/.gitconfig" ]; then
    fail ".gitconfig was replaced with a link"
  elif [ "$(cat "${home}/.gitconfig")" != "${existing}" ]; then
    fail ".gitconfig contents were modified"
  fi

  # Stow applies an invocation as a whole, so a conflict in one package must
  # leave the other packages unlinked too.
  local created
  created="$(find "${home}" -type l | wc -l | tr -d ' ')"
  if [ "${created}" -ne 0 ]; then
    fail "${created} link(s) were applied despite the conflict"
  fi

  rm -rf "${home}"
}

test_usage_is_rejected() {
  echo "an unknown subcommand exits non-zero"
  local home
  home="$(make_home)"

  if run_link "${home}" bogus > /dev/null 2>&1; then
    fail "an unknown subcommand succeeded"
  fi

  rm -rf "${home}"
}

if ! command -v stow > /dev/null 2>&1; then
  echo "GNU Stow is required. Install it with: brew install stow" >&2
  exit 1
fi

test_install_creates_expected_links
test_shared_directories_are_not_links
test_uninstall_removes_every_link
test_conflict_is_refused
test_usage_is_rejected

if [ "${failures}" -ne 0 ]; then
  printf '\n%d check(s) failed\n' "${failures}" >&2
  exit 1
fi

echo
echo "all checks passed"
