#!/usr/sbin/bash

# Configure locales
if ! grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen; then
    echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
    echo "fr_FR.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
    sudo locale-gen
    echo "LANG=fr_FR.UTF-8" | sudo tee /etc/locale.conf
fi

sudo pacman -Syu

sudo pacman -Sy --noconfirm zsh cmake nodejs npm python stow gcc tmux zlib wezterm fastfetch wget luarocks go lua51 neovim fd fzf lazygit

cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Add multilib repository if not already present
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    sudo tee -a /etc/pacman.conf >/dev/null <<EOT
[multilib]
Include = /etc/pacman.d/mirrorlist
EOT
fi

yay -S nvidia-dkms nvidia-utils lib32-nvidia-utils

rm -rf ~/.oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/mroth/evalcache ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/evalcache

# Change default shell to zsh
chsh -s /usr/bin/zsh

stow .

if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source ~/.cargo/env
fi

cargo install starship eza zoxide ripgrep

sudo npm install -g @anthropic-ai/claude-code