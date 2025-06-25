# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive macOS dotfiles repository that uses GNU Stow for configuration management. It automates the complete setup of a development environment including shell, editors, terminal multiplexers, and system preferences.

## Architecture

### Stow-based Configuration Management
- Configurations are stored in `dotfiles/` directory
- Files prefixed with `dot-` get symlinked without the prefix (e.g., `dot-zshrc` → `~/.zshrc`)
- Directory structure mirrors the target home directory structure

### Modular Organization
- **Neovim**: Full Lua configuration with lazy.nvim plugin manager (`dotfiles/dot-config/nvim/`)
- **Tmux**: Comprehensive setup with TPM plugin manager (`dotfiles/dot-config/tmux/`)
- **Shell**: Zsh with Oh My Zsh, Starship prompt, and modern CLI tools replacements
- **Git**: Professional setup with GPG signing and commit templates
- **System**: macOS-specific configurations and homebrew package management

## Common Commands

### Installation and Setup
```bash
# Complete environment setup (interactive)
./setup.sh

# Manual tmux plugin installation (if needed)
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
# Then press Ctrl+I in tmux to install plugins

# Install git pre-commit hook to prevent secret leakage
cp ./hooks/pre-commit .git/hooks
```

### Development Workflow
```bash
# Apply configuration changes (after editing files in dotfiles/)
stow -t ~ dotfiles

# Remove/unstow configurations
stow -D -t ~ dotfiles

# Reload configurations
source ~/.zshrc  # for shell changes
tmux source-file ~/.config/tmux/tmux.conf  # for tmux changes
```

### Package Management
```bash
# Install/update homebrew packages
brew bundle --file=homebrew/Brewfile

# Add new packages
echo 'brew "package-name"' >> homebrew/Brewfile
```

## Key Configuration Patterns

### Performance Optimizations
- Version managers (pyenv, nvm, jenv) use lazy loading to improve shell startup time
- Zsh configurations include evalcache plugin for expensive command caching
- Shell performance can be benchmarked with built-in aliases

### Theme Consistency
- Catppuccin theme is used consistently across all applications
- Nerd Fonts provide icon integration throughout terminal applications
- Modern CLI tools replace traditional ones (eza for ls, bat for cat, zoxide for cd)

### Security
- GPG signing enabled for git commits and tags
- Pre-commit hook prevents secret leakage using gitleaks
- Karabiner keyboard modifications for enhanced security shortcuts

## Troubleshooting

### Karabiner Issues
If Karabiner Elements doesn't work properly, check: https://github.com/pqrs-org/Karabiner-Elements/issues/3620

### Common Setup Issues
- Ensure Xcode Command Line Tools are installed before running setup
- For Apple Silicon Macs, Homebrew path may need manual addition to shell profile
- Tmux plugins require manual installation if TPM setup fails during automated install

## Important Files

- `setup.sh`: Main installation script with interactive prompts
- `homebrew/Brewfile`: Complete package manifest for development environment
- `dotfiles/dot-config/nvim/`: Modular Neovim configuration with separate plugin files
- `dotfiles/dot-config/tmux/tmux.conf`: Comprehensive tmux configuration
- `scripts/`: Utility scripts for installation and system configuration
