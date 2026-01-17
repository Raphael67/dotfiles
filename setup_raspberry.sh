#!/usr/bin/bash

# Source environment variables if .env exists
if [[ -f "$(dirname "$0")/.env" ]]; then
    source "$(dirname "$0")/.env"
fi

. scripts/utils.sh

info "Dotfiles installation initialized..."
read -p "Install apps? [y/n] " install_apps
read -p "Overwrite existing dotfiles? [y/n] " overwrite_dotfiles

# ====================
# Locales
# ====================

printf "\n"
info "===================="
info "Locales"
info "===================="

DEFAULT_LOCALE="${DOTFILES_LOCALE:-en_US.UTF-8}"
EXTRA_LOCALES="${DOTFILES_EXTRA_LOCALES:-fr_FR.UTF-8}"

if ! grep -q "^${DEFAULT_LOCALE} UTF-8" /etc/locale.gen; then
    echo "${DEFAULT_LOCALE} UTF-8" | sudo tee -a /etc/locale.gen
    for locale in $EXTRA_LOCALES; do
        echo "${locale} UTF-8" | sudo tee -a /etc/locale.gen
    done
    sudo locale-gen
    echo "LANG=${DEFAULT_LOCALE}" | sudo tee /etc/locale.conf
fi

if [[ "$install_apps" == "y" ]]; then
    # ====================
    # Cleaning
    # ====================

    printf "\n"
    info "===================="
    info "Cleaning"
    info "===================="

    sudo rm -rf ~/.cache ~/.zsh-evalcache

    # ====================
    # Pacman packages
    # ====================

    printf "\n"
    info "===================="
    info "Pacman"
    info "===================="

    sudo pacman -Syu --noconfirm \
        zsh \
        cmake \
        python \
        python-pip \
        pyenv \
        stow \
        gcc \
        tmux \
        zlib \
        fastfetch \
        wget \
        curl \
        luarocks \
        go \
        lua51 \
        neovim \
        fd \
        fzf \
        lazygit \
        jdk-openjdk \
        ruby \
        bat \
        ffmpeg \
        git \
        gitleaks \
        diff-so-fancy \
        base-devel
    # Note: nodejs/npm installed via nvm, bun is not available on ARM (aarch64)

    # ====================
    # Yay (AUR helper)
    # ====================

    printf "\n"
    info "===================="
    info "Yay"
    info "===================="

    if ! command -v yay >/dev/null 2>&1; then
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay
    else
        info "Yay already installed, skipping..."
    fi

    # ====================
    # AUR packages
    # ====================

    printf "\n"
    info "===================="
    info "AUR Packages"
    info "===================="

    yay -Syu --noconfirm \
        chruby \
        ruby-bundler

    # ====================
    # Rust
    # ====================

    printf "\n"
    info "===================="
    info "Rust"
    info "===================="

    if ! command -v rustup >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    else
        info "Rust already installed, updating..."
        rustup update
    fi

    # Ensure cargo is in PATH
    [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

    cargo install starship eza zoxide ripgrep

    # ====================
    # NVM (Node Version Manager)
    # ====================

    printf "\n"
    info "===================="
    info "NVM"
    info "===================="

    export NVM_DIR="$HOME/.nvm"
    if [[ ! -d "$NVM_DIR" ]] || [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
        # Clean up incomplete installation
        rm -rf "$NVM_DIR"
        mkdir -p "$NVM_DIR"
        # Download and install nvm (always latest)
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
    else
        info "NVM already installed, skipping..."
    fi

    # Load nvm for current session
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install LTS version of Node.js if not already installed
    if ! nvm ls --no-colors | grep -q "lts"; then
        nvm install --lts
    fi
    nvm use --lts

    # ====================
    # Zsh & Oh My Zsh
    # ====================

    printf "\n"
    info "===================="
    info "Zsh"
    info "===================="

    if [[ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        # Remove incomplete installation if exists
        rm -rf "$HOME/.oh-my-zsh"
        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        # Remove the default .zshrc created by oh-my-zsh (we'll use our own via stow)
        rm -f "$HOME/.zshrc"
    else
        info "Oh My Zsh already installed, skipping..."
    fi

    # Install zsh plugins
    if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi

    if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi

    if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/evalcache" ]]; then
        git clone https://github.com/mroth/evalcache ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/evalcache
    fi

    # Change default shell to zsh
    if [[ "$SHELL" != *"zsh"* ]]; then
        sudo chsh -s /usr/bin/zsh $USER
    fi

    # ====================
    # Jenv (Java version manager)
    # ====================

    printf "\n"
    info "===================="
    info "Jenv"
    info "===================="

    if [[ ! -d "$HOME/.jenv" ]]; then
        git clone https://github.com/jenv/jenv.git ~/.jenv
    else
        info "Jenv already installed, skipping..."
    fi
    export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/default}"

    # ====================
    # NPM packages (using nvm's npm)
    # ====================

    printf "\n"
    info "===================="
    info "NPM Packages"
    info "===================="

    # Use npm from nvm (should be loaded at this point)
    if type npm &>/dev/null; then
        npm install -g neovim
    else
        warning "npm not available, skipping neovim npm package"
    fi

    # ====================
    # Tmux Plugin Manager
    # ====================

    printf "\n"
    info "===================="
    info "Tmux Plugin Manager"
    info "===================="

    if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
        git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
    else
        info "TPM already installed, skipping..."
    fi

    # Install tmux plugins automatically
    info "Installing tmux plugins..."
    ~/.config/tmux/plugins/tpm/bin/install_plugins

    # ====================
    # Claude Code
    # ====================

    printf "\n"
    info "===================="
    info "Claude Code"
    info "===================="

    export PATH="$HOME/.local/bin:$PATH"
    if ! command -v claude >/dev/null 2>&1; then
        # Check if Claude binary exists but isn't linked
        CLAUDE_BIN=$(find ~/.claude/downloads -name "claude-*-linux-*" -type f 2>/dev/null | head -1)
        if [[ -n "$CLAUDE_BIN" && -x "$CLAUDE_BIN" ]]; then
            info "Claude binary found, creating symlink..."
            mkdir -p ~/.local/bin
            ln -sf "$CLAUDE_BIN" ~/.local/bin/claude
        else
            # Install via official script (recommended)
            # Retry up to 3 times if download fails
            for i in 1 2 3; do
                if curl -fsSL https://claude.ai/install.sh | bash; then
                    break
                else
                    warning "Claude install attempt $i failed, retrying..."
                    sleep 2
                fi
            done
        fi
    else
        info "Claude Code already installed, skipping..."
    fi
fi

# ====================
# Stow
# ====================

printf "\n"
info "===================="
info "Stow"
info "===================="

if [[ "$overwrite_dotfiles" == "y" ]]; then
    # Remove existing dotfiles to avoid stow conflicts
    rm -f ~/.zshrc ~/.zprofile

    stow .
    success "Dotfiles set up successfully."
else
    info "Skipping dotfiles stow."
fi

printf "\n"
success "Setup complete! Please restart your shell or run: source ~/.zshrc"
