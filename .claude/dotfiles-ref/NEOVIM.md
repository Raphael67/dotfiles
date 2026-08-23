# Neovim Configuration Reference

## Directory Structure

```
dotfiles/dot-config/nvim/
├── init.lua              # Entry point, lazy.nvim bootstrap
├── lazy-lock.json        # Plugin version lock file
├── lsp/                  # Per-server LSP override files (auto-discovered on
│   │                     # the runtimepath, deep-merged over lspconfig's defaults)
│   ├── basedpyright.lua  # NOT enabled — absent from lsp.lua's `servers` table (dead file)
│   ├── html.lua
│   ├── lua_ls.lua
│   ├── pylsp.lua
│   └── ruff.lua
└── lua/
    ├── core/
    │   ├── options.lua   # Vim options (tabstop, diagnostics config, etc.)
    │   ├── keymaps.lua   # Global key mappings
    │   ├── auto_save.lua # Auto-save behavior
    │   └── logging.lua   # Persistent, rolling error/warning log
    └── plugins/          # One file per plugin/feature
        ├── telescope.lua
        ├── treesitter.lua
        ├── lsp.lua
        ├── autocompletion.lua
        ├── conform.lua
        ├── lint.lua
        ├── lualine.lua
        ├── bufferline.lua
        ├── neotree.lua
        ├── snacks.lua
        ├── comment.lua
        ├── debug.lua
        ├── gitsigns.lua
        ├── database.lua
        ├── misc.lua
        ├── harpoon.lua
        ├── aerial.lua
        ├── vim-tmux-navigator.lua
        ├── rust.lua
        ├── trouble.lua
        ├── grug-far.lua
        ├── oil.lua
        ├── render-markdown.lua
        ├── persistence.lua
        └── claude.lua
```

## lazy.nvim Plugin Manager

### Bootstrap Pattern

```lua
-- In init.lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        lazypath
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    require("plugins.telescope"),
    require("plugins.treesitter"),
    -- ... more plugins
})
```

### Plugin Specification Pattern

```lua
-- lua/plugins/example.lua
return {
    "author/plugin-name",
    dependencies = {
        "dep1/plugin",
        "dep2/plugin",
    },
    event = "BufRead",        -- Lazy load on event
    ft = { "lua", "python" }, -- Lazy load for filetypes
    keys = {                  -- Lazy load on keymap
        { "<leader>f", desc = "Find" },
    },
    opts = {                  -- Shorthand for setup(opts)
        option1 = "value",
    },
    config = function()       -- Full config function
        require("plugin").setup({
            -- configuration
        })
    end,
}
```

### Lazy Loading Strategies

| Option | Use Case |
|--------|----------|
| `event = "BufRead"` | Load when opening a file |
| `event = "VimEnter"` | Load after startup |
| `event = "InsertEnter"` | Load on entering insert mode |
| `ft = {"lua"}` | Load for specific filetypes |
| `cmd = "Command"` | Load when command is invoked |
| `keys = {...}` | Load when keymap is triggered |
| `lazy = false` | Load immediately (default) |

## Adding a New Plugin

1. Create plugin file:
   ```bash
   touch dotfiles/dot-config/nvim/lua/plugins/newplugin.lua
   ```

2. Write specification:
   ```lua
   -- lua/plugins/newplugin.lua
   return {
       "author/plugin-name",
       config = function()
           require("plugin-name").setup({})
       end,
   }
   ```

3. Add to init.lua:
   ```lua
   require("lazy").setup({
       -- existing plugins...
       require("plugins.newplugin"),
   })
   ```

4. Sync plugins:
   ```vim
   :Lazy sync
   ```

### Plugin Migrations (superseded plugins)

A few plugins in this config replaced older ones wholesale — useful context if you see
references to the old names in history or elsewhere:

- **snacks.nvim** (`plugins/snacks.lua`) replaced **noice.nvim**, **indent-blankline.nvim**,
  **lazygit.nvim**, and **vim-bbye** — it now provides the notifier, indent guides, the
  lazygit float, and buffer-delete (`Snacks.bufdelete()`, wired to `<leader>x` in
  `keymaps.lua`) that those four plugins used to provide separately.
- **conform.nvim** (`plugins/conform.lua`, formatting) + **nvim-lint** (`plugins/lint.lua`,
  linting) replaced **none-ls.nvim**/**null-ls.nvim** entirely. Format-on-save is gated by
  `vim.g.disable_autoformat` / `vim.b.disable_autoformat`, toggleable via `<leader>sn`
  (save without formatting) or `:FormatDisable`/`:FormatEnable`.

## LSP Configuration

### Native `vim.lsp.config` / `vim.lsp.enable` API (Neovim 0.11+)

This repo does **not** call the old `lspconfig.<server>.setup({...})` pattern. `lsp.lua`
uses the native API instead:

1. `vim.lsp.config("*", { capabilities = ... })` sets defaults shared by every server
   (here, just `blink.cmp`'s completion capabilities).
2. Per-server overrides live in top-level `lsp/<name>.lua` files (e.g. `lsp/lua_ls.lua`,
   `lsp/ruff.lua`) — Neovim auto-discovers these on the runtimepath and deep-merges them
   over nvim-lspconfig's bundled defaults for that server name.
3. `vim.lsp.enable(servers)` activates a list of server names — this is what actually
   turns a server on, replacing `lspconfig.<server>.setup()`.

```lua
-- lua/plugins/lsp.lua (abridged)
local servers = {
    "html", "ts_ls", "lua_ls", "dockerls", "docker_compose_language_service",
    "pylsp", "ruff", "tailwindcss", "jsonls", "sqlls", "yamlls", "bashls",
    "graphql", "cssls", "ltex_plus", "texlab",
    -- rust_analyzer is intentionally absent — rustaceanvim drives it directly, see below.
}

vim.lsp.config("*", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
})

require("mason").setup()
-- mason-lspconfig kept PASSIVE (automatic_enable = false): it never enables servers
-- itself (that would double-attach alongside vim.lsp.enable). Used only so
-- mason-tool-installer can translate lspconfig names -> Mason package names.
require("mason-lspconfig").setup({ automatic_enable = false })

require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

vim.lsp.enable(servers)
```

> **Gotcha — rustaceanvim owns `rust_analyzer`:** `rust.lua`'s `rustaceanvim` plugin
> configures and attaches `rust-analyzer` itself on the `rust` filetype. Do **not** also
> add `"rust_analyzer"` to the `servers` table / `vim.lsp.enable()` list — doing so
> double-attaches the same LSP client to Rust buffers.

> **Migration note — recreating lspconfig's old `commands` field:** the native
> `vim.lsp.config` API ignores lspconfig's legacy per-server `commands` table (used e.g.
> for Ruff's `ruff.applyAutofix` / `ruff.applyOrganizeImports` code actions). `lsp.lua`
> recreates these as real user commands (`:RuffAutofix`, `:RuffOrganizeImports`) inside
> the `LspAttach` autocmd, calling `client:exec_cmd({ command = ..., arguments = ... })`
> directly — the 0.12 replacement for the deprecated `vim.lsp.buf.execute_command`. This
> is the pattern to follow when porting any other lspconfig-era server config that relied
> on custom `commands`.

`mason-lspconfig` is still installed but **passive** — it is used only to translate Mason
package names to LSP server names for `mason-tool-installer`, not to enable servers.

### LSP Keymaps (on attach)

Navigation keymaps (`gd`, `gr`, `gI`, `<leader>D`, `<leader>ds`, `<leader>ws`) are routed through **Telescope builtins** so results open in a picker; rename/code-action/hover use `vim.lsp.buf.*` directly:

```lua
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
        local opts = { buffer = event.buf }
        local tb = require("telescope.builtin")
        vim.keymap.set("n", "gd", tb.lsp_definitions, opts)       -- Telescope picker
        vim.keymap.set("n", "gr", tb.lsp_references, opts)        -- Telescope picker
        vim.keymap.set("n", "gI", tb.lsp_implementations, opts)   -- Telescope picker
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    end,
})
```

> **Neovim 0.12 LSP API:** Use the **method-call form** `client:supports_method("textDocument/formatting")` (colon). The old dot-call `client.supports_method(...)` is deprecated in 0.12. Also: `vim.lsp.semantic_tokens.start()/stop()` were renamed to `enable()`, and JSON `null` in LSP messages is now `vim.NIL` (not `nil`).

### Adding a New Language Server

1. Add the server name to the `servers` table in `lsp.lua` — this is what gets passed to
   `vim.lsp.enable(servers)`.

2. (Optional) Add an `lsp/<name>.lua` override file at the repo's `nvim/lsp/` root for
   server-specific `settings` — it's auto-discovered on the runtimepath and deep-merged
   over nvim-lspconfig's bundled defaults. See `lsp/lua_ls.lua` or `lsp/ruff.lua` for
   examples.

3. The server binary itself is installed by `mason-tool-installer`'s `ensure_installed`
   list in `lsp.lua` (this list is `servers` plus a few standalone formatter/linter
   binaries) — no manual `:MasonInstall` needed, though it still works.

4. Restart Neovim (or `:Lazy reload lsp.lua` equivalent) so `vim.lsp.enable(servers)` picks
   up the new entry.

## Treesitter Configuration (`main` branch — Neovim 0.12+)

> **Important:** `nvim-treesitter` was archived (read-only) on **2026-04-03**. This repo migrated to the `main` branch (pinned to a known-good commit, `pin = true`), which has a **completely different API** from the old `master` branch. The legacy `require("nvim-treesitter.configs").setup({...})` module **no longer exists** — using it throws a `require` error.

Key differences on `main`:

| `master` (old) | `main` (current) |
|----------------|------------------|
| `require("nvim-treesitter.configs").setup{}` | `require("nvim-treesitter").setup()` |
| `ensure_installed` / `auto_install` options | manual `require("nvim-treesitter").install({...})` |
| `highlight = { enable = true }` | `pcall(vim.treesitter.start)` in a `FileType` autocmd |
| `indent = { enable = true }` | `vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"` |
| `incremental_selection` module | **no replacement** (dropped) |
| supports lazy-loading | `lazy = false` required |

```lua
-- lua/plugins/treesitter.lua
local ensure_installed = { "lua", "python", "javascript", "typescript", "json", "yaml", "markdown", "bash" }

return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    commit = "<pinned-sha>",
    pin = true,        -- archived upstream; never auto-update
    lazy = false,      -- the `main` branch does not support lazy-loading
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup()

        -- Install missing parsers (replaces ensure_installed / auto_install)
        local installed = require("nvim-treesitter.config").get_installed()
        local to_install = vim.iter(ensure_installed)
            :filter(function(p) return not vim.tbl_contains(installed, p) end)
            :totable()
        if #to_install > 0 then require("nvim-treesitter").install(to_install) end

        -- Enable highlight + indent per-buffer on FileType
        vim.api.nvim_create_autocmd("FileType", {
            pattern = ensure_installed,
            callback = function()
                pcall(vim.treesitter.start)   -- highlighting (Neovim built-in)
                vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })
    end,
}
```

> `nvim-treesitter-textobjects` also migrated to its `main` branch with a new imperative API (`require("nvim-treesitter-textobjects.select/swap/move")`) — see `treesitter.lua` for the full keymap set.

### Adding Language Support

Add the parser name to the `ensure_installed` table (it installs on next launch), or install ad-hoc:

```vim
:TSInstall <language>
```

## Catppuccin Theme

```lua
-- Already integrated in init.lua
{
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            integrations = {
                aerial = true,
                harpoon = true,
                mason = true,
                neotree = true,
                which_key = true,
                blink_cmp = true,
                gitsigns = true,
                nvimtree = true,
                treesitter = true,
                notify = true,
                snacks = true,
                render_markdown = true,
                grug_far = true,
                telescope = true,
                bufferline = true,
                mini = { enabled = true, indentscope_color = "" },
            },
        })

        -- setup must be called before loading; flavour is baked into the
        -- colorscheme name (catppuccin-latte/-frappe/-macchiato/-mocha) rather
        -- than a separate `flavour` field read at colorscheme time.
        vim.cmd.colorscheme("catppuccin-macchiato")
    end,
}
```

## Key Options (from options.lua)

```lua
-- Indentation
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.expandtab = true
vim.o.smartindent = true

-- Display
vim.wo.number = true
vim.o.relativenumber = true
vim.wo.signcolumn = "yes"
vim.opt.termguicolors = true
vim.o.wrap = false
vim.o.scrolloff = 8

-- Search
vim.o.hlsearch = true
vim.o.incsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true

-- System
vim.o.clipboard = "unnamedplus"
vim.o.mouse = "a"
vim.o.updatetime = 50

-- Files
vim.o.swapfile = false
vim.o.backup = false
vim.o.undofile = true
vim.o.undodir = os.getenv("HOME") .. "/.vim/undodir"
```

> **Portability gotcha — language host providers:** `options.lua` pins
> `vim.g.python3_host_prog` to a dedicated venv (`~/.local/share/nvim/py-provider/bin/python`)
> that has `pynvim` installed, since the system Python usually doesn't. `vim.g.node_host_prog`
> is resolved via `vim.fn.glob("~/.local/share/nvm/versions/node/*/bin/neovim-node-host")`
> and picks the highest-versioned match, rather than hardcoding a version — this survives
> `nvm` node upgrades without editing the config, consistent with this repo's "nvm owns
> node" policy (see the top-level `CLAUDE.md`). Both are no-ops if the underlying host
> isn't present.

## Common Keymaps

### Leader Key
```lua
vim.g.mapleader = " "
vim.g.maplocalleader = " "
```

### Telescope
```lua
vim.keymap.set("n", "<leader>ff", builtin.find_files)
vim.keymap.set("n", "<leader>fg", builtin.live_grep)
vim.keymap.set("n", "<leader>fb", builtin.buffers)
```

### Neo-tree
```lua
vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>")
```

### Harpoon
```lua
vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)
```

### Sessions

Session management is handled by **persistence.nvim** (`plugins/persistence.lua`), not
manual `:mksession`/`:source` keymaps. The old `<leader>ss`/`<leader>sl` bindings for
`mksession!`/`source` are commented out in `keymaps.lua` — persistence.nvim's own
autoload/autosave replaces them.

## Plugin Files Reference

| File | Plugin | Purpose |
|------|--------|---------|
| `telescope.lua` | nvim-telescope | Fuzzy finder |
| `treesitter.lua` | nvim-treesitter | Syntax highlighting |
| `lsp.lua` | nvim-lspconfig + Mason | Language servers (native `vim.lsp.enable` API) |
| `autocompletion.lua` | blink.cmp | Completion with ghost text, fuzzy matching |
| `conform.lua` | conform.nvim | Formatting (format-on-save, `<leader>F`) |
| `lint.lua` | nvim-lint | Linting |
| `lualine.lua` | lualine.nvim | Status line |
| `bufferline.lua` | bufferline.nvim | Buffer tabs |
| `neotree.lua` | neo-tree.nvim | File explorer |
| `snacks.lua` | snacks.nvim | Notifier, indent guides, lazygit float, buffer-delete, misc QoL |
| `gitsigns.lua` | gitsigns.nvim | Git markers |
| `harpoon.lua` | harpoon | Quick file navigation |
| `aerial.lua` | aerial.nvim | Code outline |
| `vim-tmux-navigator.lua` | - | Cross-pane navigation |
| `comment.lua` | Comment.nvim | Comment toggling |
| `debug.lua` | nvim-dap | Debugging |
| `database.lua` | vim-dadbod | Database client |
| `rust.lua` | rustaceanvim + crates.nvim | Rust LSP (drives `rust_analyzer` directly) + Cargo.toml deps |
| `trouble.lua` | trouble.nvim | Diagnostics/quickfix list UI |
| `grug-far.lua` | grug-far.nvim | Project-wide find & replace |
| `oil.lua` | oil.nvim | Buffer-based file explorer |
| `render-markdown.lua` | render-markdown.nvim | Inline markdown rendering |
| `persistence.lua` | persistence.nvim | Session save/restore |
| `claude.lua` | claude.vim | Claude integration |
| `misc.lua` | Various | Additional plugins (mini.surround, mini.icons, which-key, autopairs, etc.) |
| `core/auto_save.lua` | - | Auto-save behavior |
| `core/logging.lua` | - | Persistent, rolling error/warning log |
| `lsp/*.lua` | - | Per-server LSP override files (`lua_ls`, `ruff`, `html`, `pylsp`; `basedpyright` present but dead/unused) |

## Diagnostics Configuration

```lua
vim.diagnostic.config({
    virtual_text = false,  -- inline text can't wrap; long errors (e.g. Rust) run off-screen
    virtual_lines = true,  -- render diagnostics on wrapped lines below the code instead
    signs = {
        -- Neovim 0.12+: use signs.text instead of vim.fn.sign_define()
        text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = "󰌵",
        },
    },
    underline = true,
    update_in_insert = true,   -- show diagnostics while typing (this repo's setting)
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
    },
})
```

> **Note (Neovim 0.12):** The old `vim.fn.sign_define("DiagnosticSign*")` API is deprecated. Use `signs.text` in `vim.diagnostic.config()` instead.

### Diagnostic Keymaps

| Key | Action |
|-----|--------|
| `]d` | Next diagnostic |
| `[d` | Previous diagnostic |
| `<C-w>d` | Show diagnostic float |

## Debugging and Troubleshooting

### Health Check
```vim
:checkhealth
:checkhealth vim.lsp
:checkhealth vim.treesitter
```

### LSP Info
```vim
:lsp             " Interactive LSP client management (Neovim 0.12+)
:LspInfo         " Active clients (from lspconfig plugin)
:LspLog          " LSP logs
:LspRestart      " Restart servers
:log             " Open log files (Neovim 0.13+)
```

### Lazy Plugin Manager
```vim
:Lazy            " Open Lazy UI
:Lazy sync       " Install/update plugins
:Lazy clean      " Remove unused plugins
:Lazy health     " Check Lazy status
```

### Mason Package Manager
```vim
:Mason           " Open Mason UI
:MasonInstall    " Install packages
:MasonUpdate     " Update packages
```

### Treesitter
```vim
:TSInstall <lang>    " Install parser
:TSUpdate            " Update all parsers
:TSModuleInfo        " Show module status
```

### Check Capabilities
```lua
:lua print(vim.inspect(vim.lsp.get_clients()[1].server_capabilities))
```

### Module Reloading (Development)
```lua
package.loaded['mymodule'] = nil
require('mymodule')
```

## Performance Tips

### Startup Time
```bash
nvim --startuptime startup.log
```

### Lazy Load Plugins
- Use `event`, `ft`, `cmd`, or `keys` for lazy loading
- Don't load everything on startup

### Large Files
```lua
-- Disable features for large files
vim.api.nvim_create_autocmd("BufReadPre", {
    callback = function(args)
        local size = vim.fn.getfsize(args.file)
        if size > 1024 * 1024 then  -- 1MB
            vim.cmd("syntax off")
            vim.opt_local.foldmethod = "manual"
        end
    end,
})
```

## Upcoming Changes (Neovim 0.13, unreleased)

> **Not yet released.** As of this writing, `0.13.0` is still `v0.13.0-dev` per the
> upstream GitHub milestone — the installed stable version on this machine is `0.12.4`.
> The items below are forward-looking notes gathered from unreleased-branch changelogs;
> reverify against the actual stable release notes once 0.13 ships, as pre-release
> behavior can still change.

### Breaking Changes

- **API**: `nvim_create_autocmd()`, `nvim_exec_autocmds()`, `nvim_clear_autocmds()` no longer treat empty non-nil patterns or empty arrays as nil
- **Lua**: `vim.pos` and `vim.range` now require the `buf` parameter
- **Paths**: `stdpath("log")` moved to `stdpath("state")/logs`
- **LSP**: `reuse_win` option removed from LSP buffer functions — use `switchbuf` instead

### New Features

- **LSP navigation** (`definition`, `declaration`, `implementation`) now respects the `switchbuf` option
- **`:log` command** opens log files directly
- **`vim.net.request()`** supports custom headers via `opts.headers`
- **Terminal**: TUI re-queries background color on resume, updating `'background'` option
- **LSP snippets**: Nested snippets and `CompletionItem.preselect` support
- **Node.js plugins** can use "bun" as a runtime
- **`:Open`** without arguments uses the current file

## Common Customizations

### Add Custom Filetype

```lua
vim.filetype.add({
    extension = {
        tf = "opentofu",
        tfvars = "opentofu",
    },
    filename = {
        [".envrc"] = "bash",
    },
})
```

### Add Autocommand

```lua
vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
    end,
})
```

### Add Keymap

```lua
-- In keymaps.lua or plugin config
vim.keymap.set("n", "<leader>x", function()
    -- action
end, { desc = "Description" })
```
