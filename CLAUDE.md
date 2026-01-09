# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
**IMPORTANT** : Always use the work-completion-summary agent when you finish task to let the user know.

## Repository Overview

This is a cross-platform dotfiles repository (macOS and Linux/Raspberry Pi) that uses GNU Stow for configuration management. It automates the complete setup of a development environment including shell, editors, terminal multiplexers, and system preferences.

## Architecture

### Stow-based Configuration Management

**CRITICAL**: Always use `stow .` from the project root, never `stow <package-name>`.

The `.stowrc` file configures stow with:
- `--dir=./dotfiles` - stow directory is `./dotfiles/`
- `--target=~/` - symlinks are created in home directory
- `--dotfiles` - `dot-` prefix is converted to `.` (e.g., `dot-zshrc` → `~/.zshrc`)

**Package structure**:
- `dotfiles/dot-claude/` → `~/.claude/` (Claude Code global settings)
- `dotfiles/dot-config/` → `~/.config/` (XDG config directory)
- `dotfiles/dot-zshrc` → `~/.zshrc` (Zsh configuration)

**Important**: Using `stow dot-claude` directly does NOT work correctly - it will create symlinks in `~/` instead of `~/.claude/`. Always use `stow .` to stow all packages together, which preserves the correct directory mapping.

### Modular Organization
- **Neovim**: Full Lua configuration with lazy.nvim plugin manager (`dotfiles/dot-config/nvim/`)
- **Tmux**: Comprehensive setup with TPM plugin manager (`dotfiles/dot-config/tmux/`)
- **Shell**: Zsh with Oh My Zsh, Starship prompt, and modern CLI tools replacements
- **Git**: Professional setup with GPG signing and commit templates
- **Claude Code**: Status line, damage control hooks, and notification system (`dotfiles/dot-claude/`)
- **System**: Cross-platform configurations (macOS homebrew, Linux package management)

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
stow .

# Force restow (unlink and relink all)
stow -R .

# Remove/unstow all configurations
stow -D .

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
- Claude Code damage control hooks prevent destructive operations

### Claude Code Integration
- **Status Line** (`statusline.sh`): Custom tmux status bar showing context usage and 5-hour rolling window token tracking with color-coded progress bars
- **Damage Control Hooks** (`hooks/damage-control/`): PreToolUse hooks that validate bash commands, file edits, and writes to prevent destructive operations
- **Notification System** (`ccnotify/`): Desktop notifications for Claude Code events
- **Configuration**: Environment variables in `~/.claude/.env` (see `example.env`)

### Utility Scripts
- `ghostty-new-notmux`: Open new Ghostty window bypassing tmux auto-start
- `zsh-notmux`: Launch shell without tmux (used by ghostty-new-notmux)
- Tmux keybinding: `prefix + N` opens Ghostty window without tmux

## Troubleshooting

### Karabiner Issues
If Karabiner Elements doesn't work properly, check: https://github.com/pqrs-org/Karabiner-Elements/issues/3620

### Common Setup Issues
- Ensure Xcode Command Line Tools are installed before running setup
- For Apple Silicon Macs, Homebrew path may need manual addition to shell profile
- Tmux plugins require manual installation if TPM setup fails during automated install

### Ghostty SSH Issues
If Ghostty terminal renders incorrectly on remote servers, export terminfo:
```bash
infocmp -x | ssh user@host -- tic -x -
```

## Important Files

- `setup.sh`: Main installation script with interactive prompts
- `homebrew/Brewfile`: Complete package manifest for development environment
- `dotfiles/dot-config/nvim/`: Modular Neovim configuration with separate plugin files
- `dotfiles/dot-config/tmux/tmux.conf`: Comprehensive tmux configuration
- `dotfiles/dot-claude/statusline.sh`: Claude Code usage status bar script
- `dotfiles/dot-claude/hooks/damage-control/`: PreToolUse validation hooks
- `dotfiles/dot-local/bin/`: Utility scripts (ghostty-new-notmux, zsh-notmux)
- `scripts/`: Utility scripts for installation and system configuration
