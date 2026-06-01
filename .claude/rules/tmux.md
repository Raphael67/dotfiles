---
paths:
  - "dotfiles/dot-config/tmux/**"
---

# Tmux config rules

You are editing the stow **source** (`dotfiles/dot-config/tmux/`). Reload with `prefix + r` or `tmux source-file ~/.config/tmux/tmux.conf`.

## Layout
- `tmux.conf` declares plugins (TPM) and sources `tmux.reset.conf`, `tmux.catppuccin.conf`, `tmux.custom.conf`. Put settings/keybindings in `tmux.custom.conf`, theme tweaks in `tmux.catppuccin.conf`.
- Plugins via **TPM**: add `set -g @plugin '...'`, install with `prefix + I`. Keep the `run '.../tpm/tpm'` line last.
- **Prefix is `C-x`** (not `C-b`).

## Gotchas (do not regress)
- Catppuccin window text uses **`pane_title`** (`#{?pane_title,...}`) so Claude Code agent names show in the status bar — don't revert to plain `#W`.
- `set -g extended-keys on` + `extended-keys-format csi-u` are required for some keybindings (Claude Code / Pi).
- `allow-passthrough on` (image preview), `detach-on-destroy off`, `terminal-features ",*:RGB"` and `",*:usstyle"` (with `-sag`).
- **`%` is remapped to a vertical/down split** (standard tmux `%` is horizontal).
- `scripts/claude-info.sh` renders the Claude model/agent in the status bar from `~/.claude/tmux-model-info`.

Full reference: [.claude/dotfiles-ref/TMUX.md](../dotfiles-ref/TMUX.md)
