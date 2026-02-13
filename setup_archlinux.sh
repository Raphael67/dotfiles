#!/usr/bin/bash
# Arch Linux setup script (WSL or bare metal)
# Parallels setup_ubuntu.sh and setup_macos.sh

set -e

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/scripts/utils.sh" 2>/dev/null || {
    info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
    success() { echo -e "\033[0;32m[OK]\033[0m $1"; }
    warning() { echo -e "\033[0;33m[WARN]\033[0m $1"; }
    error() { echo -e "\033[0;31m[ERR]\033[0m $1"; }
}

info "=== Arch Linux Dotfiles Setup ==="

# Update system
info "Updating system packages..."
sudo pacman -Syu --noconfirm

# Install packages from pacman/packages.txt
info "Installing packages from pacman/packages.txt..."
grep -v '^#' "$SCRIPT_DIR/pacman/packages.txt" | grep -v '^$' | xargs sudo pacman -S --needed --noconfirm
success "Pacman packages installed"

# Install oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    success "oh-my-zsh installed"
else
    success "oh-my-zsh already installed"
fi

# Install zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/evalcache" ]; then
    info "Installing evalcache..."
    git clone https://github.com/mroth/evalcache "$ZSH_CUSTOM/plugins/evalcache"
fi
success "ZSH plugins installed"

# Install Rust toolchain
if ! command -v rustup &>/dev/null; then
    info "Installing Rust toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    success "Rust installed"
else
    rustup update
    success "Rust already installed, updated"
fi

# Install nvm + Node.js LTS
if [ ! -d "$HOME/.nvm" ] && [ ! -d "$HOME/.config/nvm" ]; then
    info "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

    export NVM_DIR="$HOME/.nvm"
    [ -d "$HOME/.config/nvm" ] && export NVM_DIR="$HOME/.config/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    info "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts
    success "nvm + Node.js LTS installed"
else
    success "nvm already installed"
fi

# Install npm global packages
if [ -f "$SCRIPT_DIR/npm/packages.txt" ]; then
    info "Installing npm global packages..."
    grep -v '^#' "$SCRIPT_DIR/npm/packages.txt" | grep -v '^$' | while read -r package; do
        npm install -g "$package"
    done
    success "npm packages installed"
fi

# Install pip/uv packages
if [ -f "$SCRIPT_DIR/pip/packages.txt" ]; then
    if command -v uv &>/dev/null; then
        info "Installing pip packages via uv..."
        grep -v '^#' "$SCRIPT_DIR/pip/packages.txt" | grep -v '^$' | while read -r package; do
            uv tool install "$package"
        done
    fi
fi

# Install tmux plugin manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    info "Installing Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    success "TPM installed"
else
    success "TPM already installed"
fi

# Stow dotfiles
info "Stowing dotfiles..."
cd "$SCRIPT_DIR" && stow .
success "Dotfiles stowed"

# Set default shell to zsh
ZSH_PATH=$(grep -m1 '/zsh$' /etc/shells)
if [ -n "$ZSH_PATH" ] && [ "$SHELL" != "$ZSH_PATH" ]; then
    info "Setting zsh as default shell..."
    chsh -s "$ZSH_PATH"
    success "Default shell set to zsh"
fi

info ""
success "=== Arch Linux setup complete ==="
info "Restart your shell or run: exec zsh"
info ""
info "Post-setup checklist:"
info "  - Run 'tmux' then press prefix+I (Ctrl+x I) to install tmux plugins"
info "  - Run 'nvim' to auto-install plugins via lazy.nvim"
info "  - Configure git GPG signing if needed"
