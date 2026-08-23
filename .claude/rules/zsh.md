---
paths:
  - "dotfiles/dot-zshrc"
  - "dotfiles/dot-zprofile"
  - "dotfiles/dot-config/zsh/**"
---

# Zsh config rules

You are editing the stow **source** (`dotfiles/dot-zshrc`, `dot-zprofile`, `dot-config/zsh/aliases.zsh`). Reload with `source ~/.zshrc`.

## Conventions
- **Aliases/functions** live in `dot-config/zsh/aliases.zsh`. `dot-zshrc` is interactive config; `dot-zprofile` is login setup.
- **XDG vars are set in `dot-zprofile`** (lines 2–5), not `dot-zshrc`. Tool paths (HISTFILE, CARGO_HOME, …) derive from them in `dot-zshrc`.
- Version managers (jenv/pyenv/nvm) are **lazy-loaded**; expensive inits use `_evalcache`. Preserve these patterns when adding tools.
- Style: quote variables, prefer `[[ ]]` and `(( ))`, `local` in functions, `const`-like discipline. Secrets via `~/.env` or `bw-fetch` — never commit.

## Cross-platform (this repo is shared macOS + Arch/WSL)
- **Guard every macOS-only path** (`/opt/homebrew`, `/Applications/...`) with `[[ -d ... ]]` / `[[ -f ... ]]`.
- **Exactly one** `brew shellenv` — the guarded block in `dot-zprofile` (lines 8–10). Remove any unguarded duplicates the Homebrew installer appends.

## Gotchas (do not regress)
- `zsh-syntax-highlighting`: `builtin` and `reserved-word` are blue `#8aadf4` (not red).
- `dot-zshrc` redefines `ls` (richer eza form) after `aliases.zsh` — the zshrc one wins at runtime.
- Tmux auto-start is **live, active code** in `dot-zshrc` (races tmux-continuum's restore, then `exec tmux attach`) — don't assume it's dead/disabled when editing nearby.
- `dot-zshrc` sources `~/.env.local`, not `~/.env` — direnv already auto-loads plain `.env`, so `.env.local` avoids double-loading.
- `NVM_DIR`'s canonical default is `~/.nvm` (XDG paths are only a fallback search) — matches the global `~/.claude/CLAUDE.md` → "Node.js: nvm owns it" policy; keep this rule and that policy in agreement.

Full reference: [.claude/dotfiles-ref/ZSH.md](../dotfiles-ref/ZSH.md) · cross-platform [WINDOWS.md](../dotfiles-ref/WINDOWS.md)
