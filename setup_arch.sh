#!/usr/sbin/bash

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

pacman -Syu

pacman -Sy --noconfirm zsh cmake nodejs python stow starship fzf gcc ripgrep tmux zlib eza zoxide lazygit wezterm fastfetch fd wget luarocks go lua51 neovim

cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

sudo tee -a /etc/pacman.conf >/dev/null <<EOT
[multilib]
/etc/pacma.d/mirrorlist
EOT

yay -S nvidia-dkms nvidia-utils lib32-nvidia-utils

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/mroth/evalcache ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/evalcache

stow .

if ! command -v rustup /dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source ~/.cargo/env
fi
