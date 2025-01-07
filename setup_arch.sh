#!/bin/bash

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8


pacman -Syu

pacman -Sy --noconfirm zsh cmake stow starship fzf gcc ripgrep tmux zlib eza zoxide lazygit wezterm fastfetch fd wget luarocks go

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/mroth/evalcache ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/evalcache

stow .