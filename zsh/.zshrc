# Load interactive-shell configuration fragments in lexical order.
ZSH_CONFIG_DIR="${HOME}/.config/zsh/conf.d"

for config in "${ZSH_CONFIG_DIR}/"*.zsh(N); do
  source "${config}"
done

unset config ZSH_CONFIG_DIR

# Keep machine-specific settings and secrets outside the repository.
[[ -r "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"
