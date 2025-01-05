#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. $SCRIPT_DIR/utils.sh

register_keyboard_shortcuts() {
    # Register CTRL+/ keyboard shortcut to avoid system beep when pressed
    info "Registering keyboard shortcuts..."
    mkdir -p "$HOME/Library/KeyBindings"
    cat >"$HOME/Library/KeyBindings/DefaultKeyBinding.dict" <<EOF
{
 "^\U002F" = "noop";
}
EOF
}

apply_osx_system_defaults() {
    # https://macos-defaults.com/

    info "Applying OSX system defaults..."

    # Enable key repeats
    defaults write -g ApplePressAndHoldEnabled -bool false

    # Set a really fast key repeat.
    defaults write NSGlobalDomain KeyRepeat -int 1

    # Expand save panel by default
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

    # Expand print panel by default
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

    # Save to disk (not to iCloud) by default
    defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

    # Disable the “Are you sure you want to open this application?” dialog
    defaults write com.apple.LaunchServices LSQuarantine -bool false

    # Finder: show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    # Disable Resume system-wide
    defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

    # Enable three finger drag
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false

    # Disable prompting to use new exteral drives as Time Machine volume
    defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

    # Hide external hard drives on desktop
    defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false

    # Hide hard drives on desktop
    defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false

    # Hide removable media hard drives on desktop
    defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

    # Hide mounted servers on desktop
    defaults write com.apple.finder ShowMountedServersOnDesktop -bool false

    # Hide icons on desktop
    defaults write com.apple.finder CreateDesktop -bool false

    # Avoid creating .DS_Store files on network volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true

    # Show hidden files inside the finder
    defaults write com.apple.finder "AppleShowAllFiles" -bool true

    # Show Status Bar
    defaults write com.apple.finder "ShowStatusBar" -bool true

    # Do not show warning when changing the file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
    defaults write com.apple.screencapture type -string "png"

    # Set weekly software update checks
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 7

    # Spaces span all displays
    defaults write com.apple.spaces "spans-displays" -bool false

    # Do not rearrange spaces automatically
    defaults write com.apple.dock "mru-spaces" -bool false

    # Set Dock autohide
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock largesize -int 128
    defaults write com.apple.dock "minimize-to-application" -bool true
    defaults write com.apple.dock tilesize -int 64
    defaults write com.apple.dock "show-recents" -bool "false"

    # Save screenshots
    defaults write com.apple.screencapture "location" -string "~/Pictures" && killall SystemUIServer

    # Finder
    defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"

    # Use list view in all Finder windows by default
    # Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    # Use AirDrop over every interface
    defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

    # Minimize windows into their application’s icon
    defaults write com.apple.dock minimize-to-application -bool true

    # Show indicator lights for open applications in the Dock
    defaults write com.apple.dock show-process-indicators -bool true
    killall Dock
}
if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    register_keyboard_shortcuts
    apply_osx_system_defaults
fi
