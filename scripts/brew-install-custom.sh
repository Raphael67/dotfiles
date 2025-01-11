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

mas install 1616831348 # Affinity designer 2
mas install 1606941598 # Affinity publisher 2
mas install 1616822987 # Affinity photo 2
mas install 409201541  # pages
mas install 409203825  # numbers
mas install 409183694  # keynote
mas install 1346247457 # Endel
