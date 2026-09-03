# Prioritize ~/.local/bin and keep PATH entries unique.
typeset -gU path PATH
path=("${HOME}/.local/bin" $path)
