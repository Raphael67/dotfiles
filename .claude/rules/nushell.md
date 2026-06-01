---
paths:
  - "dotfiles/dot-config/nushell/**"
---

# Nushell config rules

You are editing the stow **source** (`dotfiles/dot-config/nushell/`). Files: `config.nu`, `env.nu`.

## Conventions / gotchas
- **Modify settings individually**: `$env.config.show_banner = false`. Do **NOT** reassign the whole `$env.config = {...}` (resets everything).
- macOS default config dir is `~/Library/Application Support/nushell/`; it only uses `~/.config/nushell/` because `XDG_CONFIG_HOME` is set (in `dot-zprofile`). Verify with `$nu.default-config-dir`.
- Current best practice consolidates env setup into `config.nu` (`env.nu` still loads first).
- starship/zoxide load via **vendor autoload** (`$nu.vendor-autoload-dirs`) — no manual prompt config.
- For modular config use `$nu.user-autoload-dirs`; for PATH use `use std/util "path add"`.

Full reference: [.claude/dotfiles-ref/TOOLS.md](../dotfiles-ref/TOOLS.md) (Nushell section)
