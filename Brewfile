# Dependencies installed by bootstrap.sh. Homebrew itself, Git, and Zsh remain
# external prerequisites.

brew "atuin"
brew "btop"
brew "dockutil"
brew "duti"
brew "fzf"
brew "gh"
brew "jq"
brew "meta-package-manager"
brew "mise"
brew "mole"
brew "ripgrep"
brew "shellcheck"
brew "skills"
brew "starship"
brew "stow"
brew "tailscale"
brew "tmux"
brew "x-cmd"
brew "yazi"
brew "zoxide"

# GUI applications. bootstrap.sh makes Zed the default handler for a list of
# file types with duti, so Zed has to be installed here rather than by hand.
cask "chatgpt"
cask "claude"
cask "cloudflare-warp"
cask "dbeaver-community"
cask "discord"
cask "ghostty"
cask "google-chrome"
cask "google-drive"
cask "iina"
cask "notunes"
cask "openvpn-connect"
cask "orbstack"
cask "raycast"
cask "slack"
cask "spotify"
cask "stats"
# The tailscale formula above provides the CLI and daemon; this is the menu bar
# app. They install to different prefixes and coexist.
cask "tailscale-app"
cask "visual-studio-code"
cask "whatsapp"
cask "zed"
cask "zen"

# Homebrew refuses to load formulae from a third-party tap unless the tap is
# trusted, and `brew bundle install` cannot prompt. Declaring the trust here
# keeps the bootstrap non-interactive.
tap "hasansezertasan/tap", trusted: { formulae: ["cobo", "hwid", "nur", "ocom", "olink", "peta"] }
brew "hasansezertasan/tap/cobo"
brew "hasansezertasan/tap/hwid"
brew "hasansezertasan/tap/nur"
brew "hasansezertasan/tap/ocom"
brew "hasansezertasan/tap/olink"
brew "hasansezertasan/tap/peta"
