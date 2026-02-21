# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.
**IMPORTANT**: Always use the work-completion-summary agent when you finish a task.

## Repository Overview

Cross-platform dotfiles repository (macOS/Linux/Windows) using GNU Stow for symlink management.

## Project Structure: Two `.claude` Directories

This repo contains **two distinct `.claude` directories** with different scopes. Confusing them will cause errors.

| Path | Scope | Deployed To | Purpose |
|------|-------|-------------|---------|
| `./.claude/` | **Project-local** (this repo only) | Nowhere (stays in repo) | Settings, agents, and skills specific to working on the dotfiles repo itself |
| `./dotfiles/dot-claude/` | **User-global** (all projects) | `~/.claude/` (via stow) | Global Claude config: skills, commands, hooks, MCP servers, settings.json |

Similarly for `CLAUDE.md`:

| Path | Scope | Read By Claude When |
|------|-------|---------------------|
| `./CLAUDE.md` | **Project-local** | Working inside this repo (`~/Projects/dotfiles`) |
| `./dotfiles/dot-claude/CLAUDE.md` | **User-global** | Working in **any** project (stowed to `~/.claude/CLAUDE.md`) |

**Key rules:**
- **Skill files** live in `./dotfiles/dot-claude/skills/` (global), NOT `./.claude/skills/` (project-local)
- **Project-local `.claude/`** is for repo-specific tooling (e.g., `settings.local.json`, agents for this repo)
- **Global `dotfiles/dot-claude/`** is stow-managed — editing it and editing `~/.claude/` is the same file (symlinked)
- When creating or editing skills, commands, or hooks meant for all projects, use `./dotfiles/dot-claude/`

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
| `dotfiles/dot-config/git/` | `~/.config/git/` |
| `dotfiles/dot-claude/` | `~/.claude/` (global Claude config, skills, commands, hooks) |
| `homebrew/Brewfile` | Package manifest |

## Global Git Hooks

Gitleaks runs automatically on every commit via a global pre-commit hook:
- Hook location: `dotfiles/dot-config/git/hooks/pre-commit` (stowed to `~/.config/git/hooks/`)
- Enabled by `core.hooksPath` in `dotfiles/dot-config/git/config`
- Chains to repo-local hooks (husky, lefthook, etc.) if they exist
- Skip with `--no-verify` when needed

## Detailed Documentation

The **dotfiles skill** (source: `dotfiles/dot-claude/skills/dotfiles/`, deployed: `~/.claude/skills/dotfiles/`) provides comprehensive documentation:

- **ZSH.md** - Shell config, aliases, Oh-My-Zsh, lazy loading
- **NEOVIM.md** - Editor config, plugins, LSP
- **TMUX.md** - Multiplexer, TPM plugins, keybindings
- **STARSHIP.md** - Prompt configuration
- **GHOSTTY.md** - Terminal settings
- **STOW.md** - Symlink management
- **TOOLS.md** - CLI tools (bat, eza, fzf, zoxide, lazygit, bitwarden)
- **TROUBLESHOOTING.md** - Common issues and fixes

The skill auto-loads when working with shell, editor, terminal, or config topics.
