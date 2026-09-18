#!/usr/bin/env bash

# Behavioural test for link.sh. Every operation runs against a scratch HOME, so
# the real home directory is never touched.

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_DIR

# Paths the packages are expected to place in the target directory.
readonly -a EXPECTED_LINKS=(
  .agents/.skill-lock.json
  .claude/CLAUDE.md
  .config/atuin/config.toml
  .config/delegate-skills/config.json
  .config/gh/config.yml
  .config/mise/config.toml
  .config/olink/pins.json
  .config/opencode/opencode.jsonc
  .config/opencode/package.json
  .config/zed/settings.json
  .config/zsh/conf.d/00-path.zsh
  .config/zsh/conf.d/10-oh-my-zsh.zsh
  .gitconfig
  .ssh/config
  .zshrc
)

# --no-folding must leave these as real directories so applications can keep
# their own state alongside the managed files.
readonly -a EXPECTED_DIRS=(
  .agents
  .claude
  .config
  .config/atuin
  .config/delegate-skills
  .config/gh
  .config/mise
  .config/olink
  .config/opencode
  .config/zed
  .config/zsh
  .config/zsh/conf.d
  .ssh
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

run_link_from() {
  local repo="$1" home="$2"
  shift 2
  HOME="${home}" "${repo}/link.sh" "$@"
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

test_existing_skill_lock_is_adopted() {
  echo "an existing Skills CLI manifest is adopted into the agents package"
  local home fixture
  home="$(make_home)"
  fixture="$(make_home)"
  fixture="$(cd -- "${fixture}" && pwd -P)"
  cp -R "${DOTFILES_DIR}/." "${fixture}"

  mkdir -p "${home}/.agents"
  printf '%s\n' \
    '{"version":3,"skills":{"fixture-local":{"source":"example/skills","sourceType":"github","sourceUrl":"https://example.invalid/skills.git","skillPath":"skills/fixture/SKILL.md","skillFolderHash":"0000000000000000000000000000000000000000","installedAt":"2026-09-10T00:00:00.000Z","updatedAt":"2026-09-10T00:00:00.000Z"}},"dismissed":{},"lastSelectedAgents":[]}' \
    > "${home}/.agents/.skill-lock.json"

  if ! run_link_from "${fixture}" "${home}" check > /dev/null 2>&1; then
    fail "check rejected an existing Skills CLI manifest"
  fi
  if [ -L "${home}/.agents/.skill-lock.json" ]; then
    fail "check modified the existing Skills CLI manifest"
  fi

  run_link_from "${fixture}" "${home}" install > /dev/null

  local target resolved
  target="${home}/.agents/.skill-lock.json"
  if [ ! -L "${target}" ]; then
    fail ".agents/.skill-lock.json was not replaced with a symlink"
  elif [ ! -e "${target}" ]; then
    fail ".agents/.skill-lock.json is a broken symlink"
  else
    resolved="$(resolve_link "${target}")"
    if [ "${resolved}" != "${fixture}/agents/.agents/.skill-lock.json" ]; then
      fail ".agents/.skill-lock.json resolves to ${resolved}, not the agents package"
    elif ! grep -q 'fixture-local' "${fixture}/agents/.agents/.skill-lock.json"; then
      fail ".agents/.skill-lock.json did not preserve the local manifest contents"
    fi
  fi

  rm -rf "${home}"
  rm -rf "${fixture}"
}

test_conflict_prevents_skill_lock_adoption() {
  echo "an unrelated conflict prevents skill-lock adoption"
  local home
  home="$(make_home)"

  mkdir -p "${home}/.agents"
  cp "${DOTFILES_DIR}/agents/.agents/.skill-lock.json" \
    "${home}/.agents/.skill-lock.json"
  printf '%s\n' "original contents" > "${home}/.gitconfig"

  if run_link "${home}" install > /dev/null 2>&1; then
    fail "install succeeded despite an unrelated conflict"
  fi
  if [ -L "${home}/.agents/.skill-lock.json" ]; then
    fail ".agents/.skill-lock.json was adopted despite an unrelated conflict"
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

test_stale_codex_hook_link_is_dropped() {
  echo "a codex hook link left by the removed package is dropped"
  local home
  home="$(make_home)"
  mkdir -p "${home}/.codex"
  # Exactly what an earlier revision left behind: a link into the deleted
  # codex package, now dangling.
  ln -s "${DOTFILES_DIR}/codex/.codex/hooks.json" "${home}/.codex/hooks.json"

  run_link "${home}" install > /dev/null

  if [ -e "${home}/.codex/hooks.json" ] || [ -L "${home}/.codex/hooks.json" ]; then
    fail "the stale codex hook link survived install"
  fi

  # A real hook file is Codex's own and must be left alone.
  printf '%s\n' '{"hooks":{}}' > "${home}/.codex/hooks.json"
  run_link "${home}" restow > /dev/null
  if [ ! -f "${home}/.codex/hooks.json" ]; then
    fail "restow removed a real Codex hook file"
  fi

  rm -rf "${home}"
}

test_unrelated_dangling_link_survives() {
  echo "a dangling hook link owned by something else is left alone"
  local home
  home="$(make_home)"
  mkdir -p "${home}/.codex"
  ln -s "${home}/elsewhere/hooks.json" "${home}/.codex/hooks.json"

  run_link "${home}" install > /dev/null

  if [ ! -L "${home}/.codex/hooks.json" ]; then
    fail "an unrelated dangling hook link was deleted"
  fi

  rm -rf "${home}"
}

test_recreated_hook_file_is_recovered() {
  echo "a hook file recreated through the stale link is moved back home"
  local home fixture
  home="$(make_home)"
  fixture="$(make_home)"
  fixture="$(cd -- "${fixture}" && pwd -P)"
  cp -R "${DOTFILES_DIR}/." "${fixture}"

  # Codex followed the dangling link and wrote the file inside the repository
  # before link.sh ran.
  mkdir -p "${fixture}/codex/.codex" "${home}/.codex"
  printf '%s\n' '{"recreated":true}' > "${fixture}/codex/.codex/hooks.json"
  ln -s "${fixture}/codex/.codex/hooks.json" "${home}/.codex/hooks.json"

  run_link_from "${fixture}" "${home}" install > /dev/null

  if [ -L "${home}/.codex/hooks.json" ]; then
    fail "the stale link survived instead of being replaced by the file"
  elif [ ! -f "${home}/.codex/hooks.json" ]; then
    fail "the recreated hook file was not moved into the home directory"
  elif ! grep -q 'recreated' "${home}/.codex/hooks.json"; then
    fail "the recovered hook file lost its contents"
  fi
  if [ -e "${fixture}/codex/.codex/hooks.json" ]; then
    fail "the recreated hook file was left inside the repository"
  fi

  rm -rf "${home}"
  rm -rf "${fixture}"
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
test_existing_skill_lock_is_adopted
test_conflict_prevents_skill_lock_adoption
test_conflict_is_refused
test_stale_codex_hook_link_is_dropped
test_unrelated_dangling_link_survives
test_recreated_hook_file_is_recovered
test_usage_is_rejected

if [ "${failures}" -ne 0 ]; then
  printf '\n%d check(s) failed\n' "${failures}" >&2
  exit 1
fi

echo
echo "all checks passed"
