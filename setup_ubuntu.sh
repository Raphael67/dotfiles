#!/usr/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

sudo apt update -y
sudo apt upgrade -y

# Install packages from apt/packages.txt
grep -v '^#' "$SCRIPT_DIR/apt/packages.txt" | grep -v '^$' | xargs sudo apt install -y

# Install Rust and update rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env
rustup update

# Install Rust packages from rust/packages.txt
grep -v '^#' "$SCRIPT_DIR/rust/packages.txt" | grep -v '^$' | xargs -I {} cargo install {}

# Install nvm and Node.js LTS
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Load nvm to install Node
export NVM_DIR="$HOME/.nvm"
[ -d "$HOME/.config/nvm" ] && export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "Installing Node.js LTS..."
nvm install --lts
nvm use --lts

# Install npm global packages
echo "Installing npm global packages..."
grep -v '^#' "$SCRIPT_DIR/npm/packages.txt" | grep -v '^$' | while read -r package; do
    npm install -g "$package"
done

stow .

# Generate configs from templates
if [[ -f "$SCRIPT_DIR/dotfiles/dot-config/.jira/.config.yml.template" ]]; then
    echo "Generating Jira CLI config from template..."
    envsubst < "$SCRIPT_DIR/dotfiles/dot-config/.jira/.config.yml.template" > "$HOME/.config/.jira/.config.yml"
fi