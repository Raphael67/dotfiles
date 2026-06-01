# Theme Consistency & XDG Base Directory

Cross-cutting reference for the repo's theming and XDG layout. Loaded on demand (linked from the per-tool rules), not auto-injected.

## Theme Consistency — Catppuccin Macchiato

**Catppuccin Macchiato** is used consistently across all tools:

| Tool | Config Location | Theme Setting |
|------|-----------------|---------------|
| Neovim | `lua/plugins/` | `catppuccin-macchiato` |
| Tmux | `tmux.catppuccin.conf` | `macchiato` |
| Starship | `starship.toml` | `catppuccin_macchiato` palette |
| Ghostty | `config` | `theme = Catppuccin Macchiato` |
| fzf | `dot-zshrc` | Catppuccin Macchiato palette in `FZF_DEFAULT_OPTS` |
| bat | `bat/config` | `Catppuccin Macchiato` |
| lazygit | `lazygit/config.yml` | Catppuccin Macchiato |
| btop | `btop/btop.conf` | `catppuccin_macchiato` |
| k9s | `k9s/skins/` | Catppuccin Macchiato skin |

**Key colors (Macchiato):**

| Role | Hex |
|------|-----|
| Base | `#24273a` |
| Text | `#cad3f5` |
| Blue | `#8aadf4` |
| Green | `#a6da95` |
| Red | `#ed8796` |

> When adding a new themed tool, match these values and add a row to the table above.

## XDG Base Directory Compliance

### XDG Environment Variables

Set in **`dot-zprofile`** (lines 2–5) so they're available to login shells and GUI apps before `dot-zshrc` runs:

| Variable | Value | Purpose |
|----------|-------|---------|
| `XDG_CONFIG_HOME` | `$HOME/.config` | Application configs |
| `XDG_DATA_HOME` | `$HOME/.local/share` | Application data |
| `XDG_STATE_HOME` | `$HOME/.local/state` | Application state/logs |
| `XDG_CACHE_HOME` | `$HOME/.cache` | Non-essential cache |

`dot-zshrc` then derives tool-specific paths from these (HISTFILE, CARGO_HOME, RUSTUP_HOME, NPM_CONFIG_CACHE, …).

### Tools Relocated to XDG

| Tool | Old Path | New Path |
|------|----------|----------|
| zsh history | `~/.zsh_history` | `$XDG_STATE_HOME/zsh/history` |
| Oh-My-Zsh | `~/.oh-my-zsh` | `$XDG_DATA_HOME/oh-my-zsh` |
| NVM | `~/.nvm` | `$XDG_DATA_HOME/nvm` |
| zsh-evalcache | `~/.zsh-evalcache` | `$XDG_CACHE_HOME/zsh-evalcache` |

### Verification

```bash
xdg-ninja    # Audit home directory for XDG compliance
```

## See also

- Shell/startup performance & lazy loading: [ZSH.md](ZSH.md)
- Per-tool theme details: the relevant tool ref (NEOVIM/TMUX/STARSHIP/GHOSTTY/TOOLS)
- Cross-platform paths: [WINDOWS.md](WINDOWS.md)
