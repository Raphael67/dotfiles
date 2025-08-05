#!/usr/bin/bash

printf "\n"
printf "====================\n"
printf "locales\n"
printf "====================\n"

# Configure locales
if ! grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen; then
    echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
    echo "fr_FR.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
    sudo locale-gen
    echo "LANG=fr_FR.UTF-8" | sudo tee /etc/locale.conf
fi

printf "\n"
printf "====================\n"
printf "Cleaning\n"
printf "====================\n"

sudo rm -rf ~/.cache ~/.zsh-evalcache

printf "\n"
printf "====================\n"
printf "Pacman\n"
printf "====================\n"

# Add multilib repository if not already present
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    sudo tee -a /etc/pacman.conf >/dev/null <<EOT
[multilib]
Include = /etc/pacman.d/mirrorlist
EOT
fi

sudo pacman -Rsu --noconfirm zsh cmake nodejs npm python stow gcc tmux zlib ghostty fastfetch wget luarocks go lua51 neovim fd fzf lazygit jdk-openjdk ruby
sudo pacman -Syu --noconfirm zsh cmake nodejs npm python stow gcc tmux zlib ghostty fastfetch wget luarocks go lua51 neovim fd fzf lazygit jdk-openjdk ruby

if [[ -d "$HOME/.jenv" ]]; then
    git clone https://github.com/jenv/jenv.git ~/.jenv
fi
export JAVA_HOME=/usr/lib/jvm/default

printf "\n"
printf "====================\n"
printf "Yay\n"
printf "====================\n"

sudo pacman -Syu --noconfirm --needed base-devel
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si
cd -
rm -rf /tmp/yay

yay -Syu --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils

printf "\n"
printf "====================\n"
printf "Zsh\n"
printf "====================\n"

echo "setup zsh"
yay -Syu --noconfirm chruby ruby-bundler
rm -rf ~/.oh-my-zsh
RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --branch v0.7.1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/mroth/evalcache ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/evalcache
rm ~/.zshrc

# Change default shell to zsh
sudo chsh -s /usr/bin/zsh $USER

printf "\n"
printf "====================\n"
printf "Rust\n"
printf "====================\n"

if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source ~/.cargo/env
fi

cargo install starship eza zoxide ripgrep

printf "\n"
printf "====================\n"
printf "Claude\n"
printf "====================\n"

sudo npm install -g @anthropic-ai/claude-code

printf "\n"
printf "====================\n"
printf "Stow\n"
printf "====================\n"

stow .
