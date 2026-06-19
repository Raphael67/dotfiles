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

The global pre-commit hook (`dotfiles/dot-config/git/hooks/pre-commit`, stowed to
`~/.config/git/hooks/`, enabled by `core.hooksPath` in `dotfiles/dot-config/git/config`)
runs in order:
1. **Gitleaks** — secret scan; **blocks** the commit on failure.
2. **sem diff --staged** — entity-level blast radius of staged changes; **informational only**,
   never blocks (skipped silently if `sem` is not installed).
3. **Repo-local hook** (husky, lefthook, etc.) if present — chained via `exec`.

- Skip the whole chain with `--no-verify` when needed.
- `sem` is installed via cargo on all platforms (listed in `rust/packages.txt`, consumed by the
  setup scripts); see the global `dot-claude/CLAUDE.md` for usage.

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

<!-- rtk-instructions v2 -->
# RTK (Rust Token Killer)

RTK is installed and applied **automatically** — a `PreToolUse` Bash hook (`rtk hook claude`
in `~/.claude/settings.json`) transparently rewrites commands (e.g. `git status` →
`rtk git status`) for 60–90% token savings. No need to prefix commands manually.

Meta commands to run directly: `rtk gain` (savings stats), `rtk discover` (missed
opportunities), `rtk proxy <cmd>` (run unfiltered for debugging).
<!-- /rtk-instructions -->

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **dotfiles** (2340 symbols, 2553 relationships, 20 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> Index stale? Run `node .gitnexus/run.cjs analyze` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? `npx gitnexus analyze` (npm 11 crash → `npm i -g gitnexus`; #1939).

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows. For regression review, compare against the default branch: `detect_changes({scope: "compare", base_ref: "main"})`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit changes without running `detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/dotfiles/context` | Codebase overview, check index freshness |
| `gitnexus://repo/dotfiles/clusters` | All functional areas |
| `gitnexus://repo/dotfiles/processes` | All execution flows |
| `gitnexus://repo/dotfiles/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->
