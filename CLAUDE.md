# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.
**IMPORTANT**: Always use the work-completion-summary agent when you finish a task.

## Repository Overview

Cross-platform dotfiles repository (macOS/Linux) using GNU Stow for symlink management.

## Critical: Stow & Symlinks

**ALWAYS run `stow .` from project root, NEVER `stow <package-name>`.**

The `.stowrc` configures:
- `--dir=./dotfiles` - source directory
- `--target=~/` - symlinks to home
- `--dotfiles` - `dot-` prefix converts to `.` (e.g., `dot-zshrc` -> `~/.zshrc`)

**Symlink awareness**: All deployed files (e.g. `~/.zshrc`, `~/.config/nvim/`) are **symlinks** pointing back to this repo's `dotfiles/` directory. This means:
- **Reading `~/.zshrc` and reading `dotfiles/dot-zshrc` return the same content** — they are the same file.
- **Editing either path modifies the same file** — changes appear in both locations instantly.
- **Do NOT compare source vs deployed to check for drift** — they cannot diverge (unless the symlink is broken).
- **Always edit via the repo path** (`dotfiles/dot-*`) for clarity, but know that edits to `~/` paths are equivalent.
- **Use `ls -la` to verify a file is symlinked** if unsure whether stow is managing it.

## Quick Commands

```bash
stow .                              # Apply configs
stow -R .                           # Force restow
source ~/.zshrc                     # Reload shell
tmux source ~/.config/tmux/tmux.conf  # Reload tmux
```

## Key Paths

| Source | Target |
|--------|--------|
| `dotfiles/dot-zshrc` | `~/.zshrc` |
| `dotfiles/dot-config/nvim/` | `~/.config/nvim/` |
| `dotfiles/dot-config/tmux/` | `~/.config/tmux/` |
| `dotfiles/dot-config/starship/` | `~/.config/starship/` |
| `dotfiles/dot-config/ghostty/` | `~/.config/ghostty/` |
| `dotfiles/dot-claude/` | `~/.claude/` |
| `homebrew/Brewfile` | Package manifest |

## Detailed Documentation

The **dotfiles skill** (`~/.claude/skills/dotfiles/`) provides comprehensive documentation:

- **ZSH.md** - Shell config, aliases, Oh-My-Zsh, lazy loading
- **NEOVIM.md** - Editor config, plugins, LSP
- **TMUX.md** - Multiplexer, TPM plugins, keybindings
- **STARSHIP.md** - Prompt configuration
- **GHOSTTY.md** - Terminal settings
- **STOW.md** - Symlink management
- **TOOLS.md** - CLI tools (bat, eza, fzf, zoxide, lazygit, bitwarden)
- **TROUBLESHOOTING.md** - Common issues and fixes

The skill auto-loads when working with shell, editor, terminal, or config topics.
