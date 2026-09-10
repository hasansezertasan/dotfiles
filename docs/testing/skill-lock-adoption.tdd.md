# Skills Lock Adoption TDD Evidence

Source plan: none; the journey was derived from the reported Stow conflict.

## User journey

As an existing Skills CLI user, I want `link.sh install` to migrate my regular
global lock manifest, so that enabling the agents package does not abort the
rest of my dotfiles installation.

## Evidence

| # | Guarantee | Test | Type | Result |
| --- | --- | --- | --- | --- |
| 1 | An existing lock makes the pre-fix installer fail with Stow's regular-file conflict. | `./link_test.sh` before the fix | integration | RED |
| 2 | `check` previews adoption without changing the existing lock, and `install` replaces it with a package symlink. | `test_existing_skill_lock_is_adopted` in `link_test.sh` | integration | GREEN |
| 3 | Adoption preserves distinct local manifest content rather than retaining the package's original content. | `test_existing_skill_lock_is_adopted` in `link_test.sh` | integration | GREEN |
| 4 | An unrelated conflict prevents adoption before it mutates the lock. | `test_conflict_prevents_skill_lock_adoption` in `link_test.sh` | integration | GREEN |
| 5 | An unrelated existing `.gitconfig` is still refused. | `test_conflict_is_refused` in `link_test.sh` | integration | GREEN |

Final validation: `./link_test.sh` and `git diff --check` passed. This shell
test suite has no coverage reporter; its behavioral cases exercise the full
Stow invocation path.
