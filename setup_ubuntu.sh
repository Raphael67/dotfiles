#!/usr/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

stow .