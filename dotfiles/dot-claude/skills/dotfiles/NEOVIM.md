# Neovim Configuration Reference

## Directory Structure

```
dotfiles/dot-config/nvim/
├── init.lua              # Entry point, lazy.nvim bootstrap
├── lazy-lock.json        # Plugin version lock file
└── lua/
    ├── core/
    │   ├── options.lua   # Vim options (tabstop, etc.)
    │   └── keymaps.lua   # Global key mappings
    └── plugins/          # One file per plugin/feature
        ├── telescope.lua
        ├── treesitter.lua
        ├── lsp.lua
        ├── autocompletion.lua
        ├── lualine.lua
        ├── bufferline.lua
        ├── neotree.lua
        ├── lazygit.lua
        ├── gitsigns.lua
        ├── harpoon.lua
        ├── aerial.lua
        ├── vim-tmux-navigator.lua
        ├── indent-blankline.lua
        ├── comment.lua
        ├── debug.lua
        ├── database.lua
        ├── none-ls.lua
        ├── claude.lua
        └── misc.lua
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

## LSP Configuration

### Using Mason + lspconfig

```lua
-- lua/plugins/lsp.lua
return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },
    config = function()
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
                "ts_ls",
                "pyright",
                "ruff",
            },
        })

        -- Setup servers
        local lspconfig = require("lspconfig")
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        lspconfig.lua_ls.setup({ capabilities = capabilities })
        lspconfig.ts_ls.setup({ capabilities = capabilities })
        lspconfig.pyright.setup({ capabilities = capabilities })
    end,
}
```

### LSP Keymaps (on attach)

```lua
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(event)
        local opts = { buffer = event.buf }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    end,
})
```

### Adding a New Language Server

1. Open Mason:
   ```vim
   :Mason
   ```

2. Find and install server (press `i` on the server)

3. Add to `ensure_installed` list in lsp.lua

4. Configure if needed:
   ```lua
   lspconfig.newserver.setup({
       capabilities = capabilities,
       settings = {
           -- server-specific settings
       },
   })
   ```

## Treesitter Configuration

```lua
-- lua/plugins/treesitter.lua
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
                "lua", "python", "javascript", "typescript",
                "json", "yaml", "markdown", "bash",
            },
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = true },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<C-space>",
                    node_incremental = "<C-space>",
                    node_decremental = "<M-space>",
                },
            },
        })
    end,
}
```

### Adding Language Support

```vim
:TSInstall <language>
```

Or add to `ensure_installed` list.

## Catppuccin Theme

```lua
-- Already integrated in init.lua
{
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        require("catppuccin").setup({
            flavour = "macchiato",
            integrations = {
                aerial = true,
                harpoon = true,
                mason = true,
                neotree = true,
                telescope = true,
                treesitter = true,
                -- more integrations...
            },
        })
        vim.cmd.colorscheme("catppuccin")
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

## Plugin Files Reference

| File | Plugin | Purpose |
|------|--------|---------|
| `telescope.lua` | nvim-telescope | Fuzzy finder |
| `treesitter.lua` | nvim-treesitter | Syntax highlighting |
| `lsp.lua` | nvim-lspconfig + Mason | Language servers |
| `autocompletion.lua` | nvim-cmp | Code completion |
| `lualine.lua` | lualine.nvim | Status line |
| `bufferline.lua` | bufferline.nvim | Buffer tabs |
| `neotree.lua` | neo-tree.nvim | File explorer |
| `lazygit.lua` | lazygit.nvim | Git TUI integration |
| `gitsigns.lua` | gitsigns.nvim | Git markers |
| `harpoon.lua` | harpoon | Quick file navigation |
| `aerial.lua` | aerial.nvim | Code outline |
| `vim-tmux-navigator.lua` | - | Cross-pane navigation |
| `indent-blankline.lua` | - | Indentation guides |
| `comment.lua` | Comment.nvim | Comment toggling |
| `debug.lua` | nvim-dap | Debugging |
| `database.lua` | vim-dadbod | Database client |
| `none-ls.lua` | none-ls.nvim | Formatters/linters |
| `claude.lua` | claude.vim | Claude integration |
| `misc.lua` | Various | Additional plugins |

## Diagnostics Configuration

```lua
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
    },
})
```

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
:LspInfo         " Active clients
:LspLog          " LSP logs
:LspRestart      " Restart servers
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

## Common Customizations

### Add Custom Filetype

```lua
vim.filetype.add({
    extension = {
        tf = "terraform",
        tfvars = "terraform",
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
