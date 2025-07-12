# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive personal dotfiles repository that manages system configuration and application setup across macOS. The repository uses GNU Stow for symlink management and includes automated setup scripts.

## Architecture

### Directory Structure
- `dotfiles/` - Contains all configuration files organized by application
  - `dot-config/` - XDG config directory structure (.config)
  - `dot-profile` - Shell profile configuration
  - `dot-zshrc` - Zsh shell configuration
- `homebrew/Brewfile` - Package management via Homebrew Bundle
- `scripts/` - Setup and utility scripts
- `hooks/` - Git hooks for security

### Configuration Management
The repository uses Stow to create symlinks from `dotfiles/` to the home directory. Files prefixed with `dot-` are mapped to dotfiles (e.g., `dot-zshrc` → `~/.zshrc`).

## Common Commands

### Initial Setup
```bash
./setup.sh
```
This runs the complete dotfiles installation including:
- Installing Xcode Command Line Tools and Homebrew
- Installing applications via Brewfile
- Setting up shell environment (oh-my-zsh, plugins)
- Configuring tmux with TPM
- Setting macOS system defaults
- Symlinking dotfiles with Stow

### Package Management
```bash
# Install/update all packages
brew bundle --file=homebrew/Brewfile

# Install packages without applications
brew bundle --file=homebrew/Brewfile --no-cask
```

### Tmux Plugin Management
```bash
# Install TPM (Tmux Plugin Manager)
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Install plugins (within tmux)
<prefix> + I  # Ctrl-b + I by default

# Reload tmux config
<prefix> + r  # Ctrl-b + r
```

### Neovim Setup
Neovim uses lazy.nvim as the plugin manager. Plugins are auto-installed on first launch.
```bash
# Update plugins
:Lazy update

# Check plugin status
:Lazy
```

### Dotfile Updates
```bash
# Apply dotfile changes
stow .

# Force overwrite existing files
stow --adopt .
```

## Key Components

### Shell Environment
- **Zsh** with oh-my-zsh framework
- **Starship** prompt with custom Catppuccin theme
- **Zoxide** for smart directory navigation
- **EZA** as modern ls replacement

### Terminal Multiplexer
- **Tmux** with extensive plugin ecosystem via TPM
- Session management with tmux-sessionx
- Floating windows with tmux-floax
- Session persistence with tmux-resurrect/continuum

### Editor Configuration
- **Neovim** with Lua configuration
- **Lazy.nvim** plugin manager
- LSP, autocompletion, and debugging setup
- Catppuccin colorscheme consistency

### Development Tools
- Git configuration with custom ignore patterns
- Lazygit for terminal Git UI
- GitHub Copilot integration
- Karabiner-Elements for keyboard customization

## Security

The repository includes a pre-commit hook that prevents committing secrets:
```bash
cp ./hooks/pre-commit .git/hooks/
```

This hook uses gitleaks to scan for potential secrets before commits.

## Theme Consistency

All applications use the Catppuccin color scheme (specifically Macchiato variant) for visual consistency across:
- Terminal (WezTerm)
- Shell prompt (Starship)
- Editor (Neovim)
- Multiplexer (Tmux)