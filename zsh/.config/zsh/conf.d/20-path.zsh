# Keep PATH entries unique while preserving their first occurrence.
typeset -gU path PATH
path=("${HOME}/.local/bin" $path)
