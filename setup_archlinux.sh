#!/usr/bin/bash
# Arch Linux setup script (WSL or bare metal)
# Parallels setup_macos.sh

set -e

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

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

# Install AUR helper (yay) if not present
if ! command -v yay &>/dev/null; then
    info "Installing yay (AUR helper)..."
    tmp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
    (cd "$tmp_dir/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp_dir"
    success "yay installed"
else
    success "yay already installed"
fi

# Install AUR packages
info "Installing claude-code from AUR (unstable)..."
# Remove orphan files that would cause pacman file conflicts.
# This happens when a previous install left files on disk that are no longer
# tracked by any package (e.g. a failed or manually removed claude-code install).
for conflict_file in /usr/bin/claude /usr/bin/claude-code; do
    if [[ -e "$conflict_file" ]] && ! pacman -Qo "$conflict_file" &>/dev/null; then
        warning "Removing unowned file that would conflict: $conflict_file"
        sudo rm -f "$conflict_file"
    fi
done
yay -S --needed --noconfirm claude-code
success "claude-code installed"

# Install oh-my-zsh
# Support both standard and XDG-compliant install paths
OMZ_XDG="${XDG_DATA_HOME:-$HOME/.local/share}/oh-my-zsh"
OMZ_STD="$HOME/.oh-my-zsh"

if [ -d "$OMZ_XDG" ]; then
    OMZ_DIR="$OMZ_XDG"
elif [ -d "$OMZ_STD" ]; then
    OMZ_DIR="$OMZ_STD"
else
    OMZ_DIR=""
fi

if [ -n "$OMZ_DIR" ]; then
    info "Updating oh-my-zsh at $OMZ_DIR..."
    git -C "$OMZ_DIR" pull --ff-only
    success "oh-my-zsh updated"
else
    info "Installing oh-my-zsh..."
    # Unset $ZSH so the installer chooses the XDG path via ZDOTDIR/ZSH env, not a stale export
    unset ZSH
    ZSH="$OMZ_XDG" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    OMZ_DIR="$OMZ_XDG"
    success "oh-my-zsh installed at $OMZ_DIR"
fi

# Install zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$OMZ_DIR/custom}"

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

# Install Rust toolchain (XDG-compliant paths)
export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
export RUSTUP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"

# Migrate from default paths to XDG if needed
if [ -d "$HOME/.cargo" ] && [ ! -d "$CARGO_HOME" ]; then
    info "Migrating ~/.cargo to $CARGO_HOME..."
    mv "$HOME/.cargo" "$CARGO_HOME"
fi
if [ -d "$HOME/.rustup" ] && [ ! -d "$RUSTUP_HOME" ]; then
    info "Migrating ~/.rustup to $RUSTUP_HOME..."
    mv "$HOME/.rustup" "$RUSTUP_HOME"
fi

# Ensure cargo bin is on PATH for this script
export PATH="$CARGO_HOME/bin:$PATH"

if ! command -v rustup &>/dev/null; then
    info "Installing Rust toolchain..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$CARGO_HOME/env"
    success "Rust installed"
else
    if rustup toolchain list 2>/dev/null | grep -q '^[^n]'; then
        rustup update
        success "Rust already installed, updated"
    else
        info "Rustup found but no toolchain installed, installing stable..."
        rustup toolchain install stable
        rustup default stable
        success "Rust stable toolchain installed"
    fi
fi

# Install nvm + Node.js LTS
# Resolve NVM_DIR: prefer XDG path, fall back to legacy paths
export NVM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvm"
[ -d "$HOME/.nvm" ] && export NVM_DIR="$HOME/.nvm"
[ -d "$HOME/.config/nvm" ] && export NVM_DIR="$HOME/.config/nvm"

if [ ! -d "$NVM_DIR" ]; then
    info "Installing nvm..."
    # Set XDG-compliant install path before running installer
    export NVM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvm"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

    # Source nvm in the current shell (installer only adds lines to ~/.zshrc)
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    info "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts
    success "nvm + Node.js LTS installed"
else
    # Source nvm in the current shell
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm use --lts --silent 2>/dev/null
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

# Ensure XDG directories exist
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/less"

# Stow dotfiles
info "Stowing dotfiles..."
cd "$SCRIPT_DIR" && stow .
success "Dotfiles stowed"

# Generate configs from templates
if [[ -f "$SCRIPT_DIR/dotfiles/dot-config/.jira/.config.yml.template" ]]; then
    info "Generating Jira CLI config from template..."
    envsubst < "$SCRIPT_DIR/dotfiles/dot-config/.jira/.config.yml.template" > "$HOME/.config/.jira/.config.yml"
    success "Jira CLI config generated."
fi

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
