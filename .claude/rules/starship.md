---
paths:
  - "dotfiles/dot-config/starship/**"
---

# Starship prompt rules

You are editing the stow **source** (`dotfiles/dot-config/starship/starship.toml`). `STARSHIP_CONFIG` points here; reload with `source ~/.zshrc` (init is `_evalcache`'d).

## Conventions
- Config lives at `starship/starship.toml` (a **subfolder**), not `~/.config/starship.toml`. Presets must be written there: `starship preset <name> -o ~/.config/starship/starship.toml`.
- Palette is **`catppuccin_macchiato`**, defined inline in the toml.
- `format = """..."""` lists active modules in order; add a `[module]` block **and** add `$module` to the format string.
- Edit modules individually; keep the inline palette block intact.

Full reference: [.claude/dotfiles-ref/STARSHIP.md](../dotfiles-ref/STARSHIP.md)
