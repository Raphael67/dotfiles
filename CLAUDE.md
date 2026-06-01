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
| `dotfiles/dot-config/atuin/` | `~/.config/atuin/` |
| `dotfiles/dot-config/direnv/` | `~/.config/direnv/` |
| `dotfiles/dot-config/television/` | `~/.config/television/` |
| `dotfiles/dot-config/glow/` | `~/.config/glow/` |
| `dotfiles/dot-claude/` | `~/.claude/` (global Claude config, skills, commands, hooks) |
| `homebrew/Brewfile` | Package manifest |

## Cross-Platform Portability

This repo is shared between macOS and Linux (Arch on WSL). **All shell config files must be portable.**

### Pre-commit checks for shell files

Before committing changes to `dot-zprofile`, `dot-zshrc`, or any shell config:
1. **No unguarded macOS paths** — references to `/opt/homebrew/`, `/Applications/`, or other macOS-only paths must be wrapped in existence checks (`if [[ -f ... ]]` or `if [[ -d ... ]]`)
2. **No duplicate `brew shellenv`** — Homebrew's installer blindly appends `eval "$(/opt/homebrew/bin/brew shellenv)"` to `.zprofile`. The guarded block in `dot-zprofile` (lines 7-10) is the single source of truth. Remove any unguarded duplicates before committing.
3. **Guard pattern** for macOS-only tools:
   ```zsh
   if [[ -f /opt/homebrew/bin/brew ]]; then
     eval "$(/opt/homebrew/bin/brew shellenv)"
   fi
   ```

## Global Git Hooks

Gitleaks runs automatically on every commit via a global pre-commit hook:
- Hook location: `dotfiles/dot-config/git/hooks/pre-commit` (stowed to `~/.config/git/hooks/`)
- Enabled by `core.hooksPath` in `dotfiles/dot-config/git/config`
- Chains to repo-local hooks (husky, lefthook, etc.) if they exist
- Skip with `--no-verify` when needed

## Detailed Documentation

Guidance is delivered through **path-scoped rules** in `./.claude/rules/` (project-local). Each rule has `paths:` frontmatter, so Claude Code auto-loads it on demand when you edit a matching config file — no need to invoke anything.

| Rule | Auto-loads when editing | Full reference |
|------|-------------------------|----------------|
| `rules/nvim.md` | `dotfiles/dot-config/nvim/**` | `dotfiles-ref/NEOVIM.md` |
| `rules/tmux.md` | `dotfiles/dot-config/tmux/**` | `dotfiles-ref/TMUX.md` |
| `rules/zsh.md` | `dot-zshrc`, `dot-zprofile`, `dot-config/zsh/**` | `dotfiles-ref/ZSH.md` |
| `rules/starship.md` | `dotfiles/dot-config/starship/**` | `dotfiles-ref/STARSHIP.md` |
| `rules/ghostty.md` | `dotfiles/dot-config/ghostty/**` | `dotfiles-ref/GHOSTTY.md` |
| `rules/nushell.md` | `dotfiles/dot-config/nushell/**` | `dotfiles-ref/TOOLS.md` |
| `rules/cli-tools.md` | `dot-config/{bat,lazygit,atuin,direnv,television,glow}/**` | `dotfiles-ref/TOOLS.md` |
| `rules/stow.md` | `.stowrc`, `**/.stow-local-ignore` | `dotfiles-ref/STOW.md` |

- **Lean rules** (`./.claude/rules/`) hold the key conventions and gotchas; they auto-inject.
- **Full reference docs** (`./.claude/dotfiles-ref/`) are read on demand — also `TROUBLESHOOTING.md`, `WINDOWS.md`, and `THEME-XDG.md` (Catppuccin palette + XDG tables), which have no single file glob.
- **`/dotfiles-selfupdate`** (`./.claude/commands/`) refreshes the reference docs against upstream documentation and flags any rule that drifted.
