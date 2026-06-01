---
paths:
  - "dotfiles/dot-config/nvim/**"
---

# Neovim config rules

You are editing the stow **source** (`dotfiles/dot-config/nvim/`). The deployed `~/.config/nvim/` is a symlink to it — edits are live immediately.

## Conventions
- **lazy.nvim**: one file per plugin in `lua/plugins/`, returning a spec table. Register new plugins in `init.lua`'s `require("lazy").setup({...})`.
- **Options/keymaps**: `lua/core/options.lua` and `lua/core/keymaps.lua`. Indentation is 4-space (`tabstop=shiftwidth=softtabstop=4`, `expandtab`).
- **Theme**: catppuccin-macchiato.

## Gotchas (do not regress)
- **Treesitter is on the `main` branch** (Neovim 0.12+), pinned to a commit with `pin = true`, `lazy = false`. Do **NOT** use `require("nvim-treesitter.configs").setup{}` — that module doesn't exist on `main` and throws. Add parsers to the `ensure_installed` table; highlight via `pcall(vim.treesitter.start)` in a `FileType` autocmd.
- **LSP**: Mason + lspconfig; navigation keymaps (`gd`/`gr`/`gI`/`<leader>D`/`ds`/`ws`) route through `telescope.builtin`. Use the **method-call** form `client:supports_method("...")` (colon) — the dot form is deprecated in 0.12. Completion is `blink.cmp`.
- **Diagnostics**: use `signs.text` in `vim.diagnostic.config()` (not `vim.fn.sign_define`); this repo sets `update_in_insert = true`.

Full reference: [.claude/dotfiles-ref/NEOVIM.md](../dotfiles-ref/NEOVIM.md)
