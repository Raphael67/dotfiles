run_brew_bundle() {
    brewfile="$SCRIPT_DIR/../homebrew/Brewfile"
    if [ -f $brewfile ]; then
        # Run `brew bundle check`
        local check_output
        check_output=$(brew bundle check --file="$brewfile" 2>&1)

        # Check if "The Brewfile's dependencies are satisfied." is contained in the output
        if echo "$check_output" | grep -q "The Brewfile's dependencies are satisfied."; then
            warning "The Brewfile's dependencies are already satisfied."
        else
            info "Satisfying missing dependencies with 'brew bundle install'..."
            brew bundle install --file="$brewfile"
        fi
    else
        error "Brewfile not found"
        return 1
    fi
}

if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    # Check if Homebrew is installed
    if ! command -v brew &>/dev/null; then
        error "Homebrew is not installed. Please install Homebrew first."
        exit 1
    fi

    run_brew_bundle
fi

# Install Mac App Store apps from MAS_APPS environment variable
# Default: iWork apps (free, always available)
# To customize: set MAS_APPS in .env (space-separated bundle IDs)
# To skip: set MAS_APPS="" in .env
MAS_APPS_LIST="${MAS_APPS:-409201541 409203825 409183694}"
if [[ -n "$MAS_APPS_LIST" ]] && command -v mas &>/dev/null; then
    for app_id in $MAS_APPS_LIST; do
        # Skip if already installed
        if mas list | grep -q "^$app_id"; then
            info "Mac App Store app $app_id already installed, skipping"
            continue
        fi
        if ! mas install "$app_id" 2>/dev/null; then
            warning "Could not install Mac App Store app $app_id (may not be available or not purchased)"
        fi
    done
fi
