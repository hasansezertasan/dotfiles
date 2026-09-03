#!/usr/bin/env bash

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)" || exit 1
readonly DOTFILES_DIR

COMPUTER_NAME="hasansezertasan"
LANGUAGES=(en tr)
LOCALE="en_US@currency=USD"
MEASUREMENT_UNITS="Centimeters"
SCREENSHOTS_FOLDER="${HOME}/Screenshots"

# Topics
#
# - Shell dependencies & dotfile links
# - Computer & Host name
# - Localization
# - System
# - Keyboard & Input
# - Trackpad, mouse, Bluetooth accessories
# - Screen
# - Finder
# - Dock
# - Mail
# - Calendar
# - Terminal
# - Activity Monitor
# - Software Updates

# Homebrew is the external bootstrap prerequisite. Git and Zsh are normally
# available on macOS, but check them before changing anything.
BOOTSTRAP_PREREQUISITES=(brew git zsh)
MISSING_PREREQUISITES=()
for command_name in "${BOOTSTRAP_PREREQUISITES[@]}"; do
  command -v "${command_name}" > /dev/null 2>&1 ||
    MISSING_PREREQUISITES+=("${command_name}")
done
if [ ${#MISSING_PREREQUISITES[@]} -ne 0 ]; then
  echo "Missing bootstrap prerequisite(s): ${MISSING_PREREQUISITES[*]}" >&2
  exit 1
fi

# Install commands used by the bootstrap, link manager, and Zsh plugins.
FORMULAE=(dockutil duti mise starship stow zoxide)
MISSING_FORMULAE=()
for formula in "${FORMULAE[@]}"; do
  brew list --formula "${formula}" > /dev/null 2>&1 ||
    MISSING_FORMULAE+=("${formula}")
done
if [ ${#MISSING_FORMULAE[@]} -ne 0 ]; then
  brew install "${MISSING_FORMULAE[@]}" || exit 1
fi

# Detect link conflicts before installing any framework files.
"${DOTFILES_DIR}/link.sh" check || exit 1

OMZ_DIR="${ZSH:-${HOME:?HOME must be set}/.oh-my-zsh}"
readonly OMZ_DIR
if [[ -r "${OMZ_DIR}/oh-my-zsh.sh" ]]; then
  echo "Oh My Zsh is already installed at ${OMZ_DIR}"
elif [[ -e "${OMZ_DIR}" || -L "${OMZ_DIR}" ]]; then
  echo "Cannot install Oh My Zsh: ${OMZ_DIR} already exists" >&2
  exit 1
else
  git clone https://github.com/ohmyzsh/ohmyzsh.git "${OMZ_DIR}" || exit 1
fi

"${DOTFILES_DIR}/link.sh" install || exit 1

# Set by the mutating commands below when they fail, and returned at exit so a
# partial bootstrap is distinguishable from a clean one
EXIT_STATUS=0

# "System Preferences" was renamed "System Settings" in macOS 13
osascript -e 'tell application "System Settings" to quit' 2> /dev/null

# Ask for the administrator password upfront; a partial run is worse than none
sudo -v || exit 1

# Keep-alive: update existing `sudo` time stamp until this script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# Computer & Host name                                                        #
###############################################################################

# Set computer name (as done via System Preferences → Sharing)
sudo scutil --set ComputerName "$COMPUTER_NAME"
sudo scutil --set HostName "$COMPUTER_NAME"
sudo scutil --set LocalHostName "$COMPUTER_NAME"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$COMPUTER_NAME"

###############################################################################
# Localization                                                                #
###############################################################################

# Set language and text formats
defaults write NSGlobalDomain AppleLanguages -array "${LANGUAGES[@]}"
# defaults write NSGlobalDomain AppleLocale -string "$LOCALE"
# defaults write NSGlobalDomain AppleMeasurementUnits -string "$MEASUREMENT_UNITS"
# defaults write NSGlobalDomain AppleMetricUnits -bool true

# Using systemsetup might give Error:-99, can be ignored (commands still work)
# systemsetup manpage: https://ss64.com/osx/systemsetup.html

# Set the time zone
# sudo defaults write /Library/Preferences/com.apple.timezone.auto Active -bool YES
# sudo systemsetup -setusingnetworktime on

###############################################################################
# System                                                                      #
###############################################################################

# Restart automatically if the computer freezes (Error:-99 can be ignored)
# sudo systemsetup -setrestartfreeze on 2> /dev/null

# Set standby delay to 24 hours (default is 1 hour)
# sudo pmset -a standbydelay 86400

# Disable Sudden Motion Sensor
# sudo pmset -a sms 0

# Disable audio feedback when volume is changed
# defaults write com.apple.sound.beep.feedback -bool false

# Disable the sound effects on boot
# sudo nvram SystemAudioVolume=" "
# sudo nvram StartupMute=%01

# Menu bar: show battery percentage
# Lives in Control Center's per-host domain since Big Sur; the old
# com.apple.menuextra.battery ShowPercent key is a no-op
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

# Disable opening and closing window animations
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# Increase window resize speed for Cocoa applications
# defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable Resume system-wide
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# Disable the crash reporter
defaults write com.apple.CrashReporter DialogType -string "none"

# Disable Notification Center and remove the menu bar icon
# Unloading agents under /System/Library is blocked by SIP, so this can't work
# on a stock machine; left here only to document the intent
# launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null

###############################################################################
# Keyboard & Input                                                            #
###############################################################################

# Disable smart quotes and dashes as they're annoying when typing code
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Keyboard backlight: com.apple.BezelServices only applies to pre-2013 Macs.
# Modern hardware exposes these under System Settings > Keyboard with no
# scriptable defaults key.
# defaults write com.apple.BezelServices kDim -bool true
# defaults write com.apple.BezelServices kDimTime -int 300

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# 5. Disable Option + Command + Space (Spotlight Finder Search)
# Key 65 is the symbolic hotkey for "Show Finder search window"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 "<dict><key>enabled</key><false/></dict>"

###############################################################################
# Trackpad, mouse, Bluetooth accessories                                      #
###############################################################################

# Trackpad: enable tap to click for this user and for the login screen
# defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
# defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
# defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: map bottom right corner to right-click
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
# defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
# defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Trackpad: swipe between pages with three fingers
# defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true
# defaults -currentHost write NSGlobalDomain com.apple.trackpad.threeFingerHorizSwipeGesture -int 1
# defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 1

# Increase sound quality for Bluetooth headphones/headsets
# defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

###############################################################################
# Screen                                                                      #
###############################################################################

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to the ~/Screenshots folder
mkdir -p "${SCREENSHOTS_FOLDER}"
defaults write com.apple.screencapture location -string "${SCREENSHOTS_FOLDER}"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Enable subpixel font rendering on non-Apple LCDs
defaults write NSGlobalDomain AppleFontSmoothing -int 2

###############################################################################
# Finder                                                                      #
###############################################################################

# Finder: allow quitting via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true

# Finder: disable window animations and Get Info animations
defaults write com.apple.finder DisableAllAnimations -bool true

# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Finder: allow text selection in Quick Look
defaults write com.apple.finder QLEnableTextSelection -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Finder: Set Home folder as the default location for new windows (replaces 'Recents')
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Disable disk image verification
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

# Use AirDrop over every interface.
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Always open everything in Finder's column view.
# Use column view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`, `Nlsv`
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Finder Group items by Kind
defaults write com.apple.finder FXPreferredGroupBy -string "Kind"

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Expand the following File Info panes:
# "General", "Open with", and "Sharing & Permissions"
defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true Privileges -bool true

###############################################################################
# Dock                                                                        #
###############################################################################

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true

# Don't animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

# Keep the Dock permanently visible (don't auto-hide)
defaults write com.apple.dock autohide -bool false

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# No bouncing icons
defaults write com.apple.dock no-bouncing -bool true

# Disable hot corners
defaults write com.apple.dock wvous-tl-corner -int 0
defaults write com.apple.dock wvous-tr-corner -int 0
defaults write com.apple.dock wvous-bl-corner -int 0
defaults write com.apple.dock wvous-br-corner -int 0

# Don't show recently used applications in the Dock
defaults write com.apple.dock show-recents -bool false

dockutil --no-restart --remove all || EXIT_STATUS=1

###############################################################################
# Mail                                                                        #
###############################################################################

# Display emails in threaded mode
defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"

# Disable send and reply animations in Mail.app
defaults write com.apple.mail DisableReplyAnimations -bool true
defaults write com.apple.mail DisableSendAnimations -bool true

# Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Disable inline attachments (just show the icons)
defaults write com.apple.mail DisableInlineAttachmentViewing -bool true

# Disable automatic spell checking
defaults write com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"

# Disable sound for incoming mail
defaults write com.apple.mail MailSound -string ""

# Disable sound for other mail actions
defaults write com.apple.mail PlayMailSounds -bool false

# Mark all messages as read when opening a conversation
defaults write com.apple.mail ConversationViewMarkAllAsRead -bool true

# Disable including results from trash in search
defaults write com.apple.mail IndexTrash -bool false

# Automatically check for new message (not every 5 minutes)
defaults write com.apple.mail AutoFetch -bool true
defaults write com.apple.mail PollTime -string "-1"

# Show most recent message at the top in conversations
defaults write com.apple.mail ConversationViewSortDescending -bool true

###############################################################################
# Calendar                                                                    #
###############################################################################

# Show week numbers (10.8 only)
defaults write com.apple.iCal "Show Week Numbers" -bool true

# Week starts on monday
defaults write com.apple.iCal "first day of week" -int 1

###############################################################################
# Terminal                                                                    #
###############################################################################

# Terminal is not in the restart list below: this script is normally run from
# Terminal, so killing it would kill the script. Relaunch it manually for these
# to take effect.

# Only use UTF-8 in Terminal.app
defaults write com.apple.Terminal StringEncodings -array 4

# Appearance
defaults write com.apple.Terminal "Default Window Settings" -string "Pro"
defaults write com.apple.Terminal "Startup Window Settings" -string "Pro"
defaults write com.apple.Terminal ShowLineMarks -int 0

###############################################################################
# Activity Monitor                                                            #
###############################################################################

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Software Updates                                                            #
###############################################################################

# Enable the automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Check for software updates weekly (`dot update` includes software updates)
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 7

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true

# Install System data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool true

# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true

# Allow the App Store to reboot machine on macOS updates
defaults write com.apple.commerce AutoUpdateRestartRequired -bool true

###############################################################################
# File Associations                                                           #
###############################################################################

# Extensions, plus the UTI that extensionless files (LICENSE, etc.) are
# content-sniffed as
ZED_FILE_TYPES=(
  .cfg .flake8 .gitattributes .gitignore .in .ini .js .json .jsonl .jsonc
  .lock .md .opml .py .python-version .rst .toml .ts .txt .xml .yaml .yml
  public.plain-text
)

for file_type in "${ZED_FILE_TYPES[@]}"; do
  duti -s dev.zed.Zed "${file_type}" all || EXIT_STATUS=1
done

###############################################################################
# Kill affected applications                                                  #
###############################################################################

for app in "Activity Monitor" "Address Book" "Calendar" "Contacts" "Dock" "Finder" "Mail" "Safari" "SystemUIServer" "iCal"; do
  killall "${app}" &> /dev/null || true
done

exit "${EXIT_STATUS}"
