#!/bin/bash

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
    if [[ /opt/homebrew/lib/pam/pam_reattach.so ]]; then
        sed "1s/^/auth     optional     \/opt\/homebrew\/lib\/pam\/pam_reattach.so ignore_ssh\n/" /etc/pam.d/sudo_local | sudo tee /etc/pam.d/sudo_local
    fi

    npm install -g neovim

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/mroth/evalcache ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/evalcache

    echo >>/Users/raphael/.zprofile
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>/Users/raphael/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"

    rm -rf ~/.config/tmux/plugins/tpm
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
    starship -o ~/.config/starship.toml
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
