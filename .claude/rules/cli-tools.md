---
paths:
  - "dotfiles/dot-config/bat/**"
  - "dotfiles/dot-config/lazygit/**"
  - "dotfiles/dot-config/atuin/**"
  - "dotfiles/dot-config/direnv/**"
  - "dotfiles/dot-config/television/**"
  - "dotfiles/dot-config/glow/**"
---

# CLI tool config rules

You are editing the stow **source** for a CLI replacement tool. All themed tools use **Catppuccin Macchiato** — match palette key colors when adding theme settings.

## Per tool
- **bat** (`bat/config`): theme `Catppuccin Macchiato`; also drives `MANPAGER`.
- **lazygit** (`lazygit/config.yml`): Catppuccin theme; launched via `lg` alias / nvim integration.
- **atuin** (`atuin/config.toml`): shell history DB (Ctrl+R). Search/filter/workspace modes; secrets auto-filtered.
- **direnv** (`direnv/direnv.toml`, `direnvrc`): per-dir env; `~/Projects` whitelisted; custom stdlib `use_nvm`/`use_pyenv`/`layout_uv`.
- **television** (`television/`): TUI browser; cable channels in `television/cable/`.
- **glow** (`glow/`): markdown renderer.

The shell-integration wiring for atuin/direnv/television (the `_evalcache ... init` lines) lives in `dot-zshrc` — see the ZSH ref. For secrets, use `bw-fetch` / `bw-unlock` (Bitwarden CLI); never commit credentials.

Full reference: [.claude/dotfiles-ref/TOOLS.md](../dotfiles-ref/TOOLS.md) · integrations [ZSH.md](../dotfiles-ref/ZSH.md)
