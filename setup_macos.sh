#!/bin/bash

# Source environment variables if .env exists
if [[ -f "$(dirname "$0")/.env" ]]; then
    source "$(dirname "$0")/.env"
fi

. scripts/utils.sh
. scripts/prerequisites.sh
. scripts/brew-install-custom.sh
. scripts/osx-defaults.sh

info "Dotfiles intallation initialized..."
read -p "Install apps? [y/n] " install_apps
read -p "Overwrite existing dotfiles? [y/n] " overwrite_dotfiles

if [[ "$install_apps" == "y" ]]; then
    printf "\n"
    info "===================="
    info "Prerequisites"
    info "===================="

    install_xcode
    install_homebrew

    if ! command -v rustup /dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        source ~/.cargo/env
    fi

    printf "\n"
    info "===================="
    info "Apps"
    info "===================="

    run_brew_bundle

    sed "s/^#auth/auth/" /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local
    BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
    if [[ -f "${BREW_PREFIX}/lib/pam/pam_reattach.so" ]]; then
        sed "1s|^|auth     optional     ${BREW_PREFIX}/lib/pam/pam_reattach.so ignore_ssh\n|" /etc/pam.d/sudo_local | sudo tee /etc/pam.d/sudo_local
    fi

    # Install npm global packages from packages.txt
    info "Installing npm global packages..."
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            npm install -g "$line"
        fi
    done < npm/packages.txt

    # Install Python tools with uv (isolated environments)
    info "Installing Python tools..."
    if command -v uv &> /dev/null; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
                uv tool install "$line"
            fi
        done < pip/packages.txt
    else
        info "Warning: uv not found, skipping Python tools"
    fi

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/mroth/evalcache ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/evalcache

    USER_HOME="${DOTFILES_HOME:-$HOME}"
    BREW_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}"
    echo >>"${USER_HOME}/.zprofile"
    echo "eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\"" >>"${USER_HOME}/.zprofile"
    eval "$(${BREW_PREFIX}/bin/brew shellenv)"

    rm -rf ~/.config/tmux/plugins/tpm
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
    export STARSHIP_CONFIG=~/.config/starship.toml
fi

printf "\n"
info "===================="
info "OSX System Defaults"
info "===================="

register_keyboard_shortcuts
apply_osx_system_defaults

printf "\n"
info "===================="
info "Terminal"
info "===================="

info "Adding .hushlogin file to suppress 'last login' message in terminal..."
touch ~/.hushlogin

printf "\n"
info "===================="
info "Stow"
info "===================="

if [[ "$overwrite_dotfiles" == "y" ]]; then
    stow .
    success "Dotfiles set up successfully."
fi

# Generate configs from templates
if [[ -f "$SCRIPT_DIR/dotfiles/dot-config/.jira/.config.yml.template" ]]; then
    info "Generating Jira CLI config from template..."
    envsubst < "$SCRIPT_DIR/dotfiles/dot-config/.jira/.config.yml.template" > "$HOME/.config/.jira/.config.yml"
    success "Jira CLI config generated."
fi

# Symlink vscode settings
USER_HOME="${DOTFILES_HOME:-$HOME}"
rm "${USER_HOME}/Library/Application Support/Code/User/settings.json"
ln -s $(pwd)/dotfiles/dot-config/Code/User/settings.json "${USER_HOME}/Library/Application Support/Code/User/settings.json"