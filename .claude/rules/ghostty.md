---
paths:
  - "dotfiles/dot-config/ghostty/**"
---

# Ghostty terminal rules

You are editing the stow **source** (`dotfiles/dot-config/ghostty/config`). Reload with `Cmd+Shift+,` (macOS); some options need a new window.

## Syntax
- `key = value`, **one setting per line, no inline comments**. Empty value resets to default.
- The config file is named `config` here; `config.ghostty` is also supported (1.2.3+) and would take precedence if both existed.

## Conventions / gotchas (do not regress)
- Theme: `theme = Catppuccin Macchiato` (Title Case, 1.2.0+ — not kebab-case).
- Background blur uses **`background-blur`** (boolean/integer). There is **no** `background-blur-radius` key — don't reintroduce it.
- Shell integration auto-injects for bash/zsh/fish/elvish/**nushell**; use `shell-integration = detect`.
- For remote terminfo, prefer `ghostty +ssh user@host` (1.3.0+) over manual `infocmp` export.

Full reference: [.claude/dotfiles-ref/GHOSTTY.md](../dotfiles-ref/GHOSTTY.md)
