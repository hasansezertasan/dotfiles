export ZSH="${ZSH:-${HOME}/.oh-my-zsh}"

ZSH_THEME="robbyrussell"
plugins=(git brew starship zoxide mise)

if [[ -r "${ZSH}/oh-my-zsh.sh" ]]; then
  source "${ZSH}/oh-my-zsh.sh"
fi
