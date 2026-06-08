require("core.options")
require("core.keymaps")
require("core.auto_save")
-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    error("Error cloning lazy.nvim:\n" .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require("lazy").setup({
  require("plugins.telescope"),
  require("plugins.treesitter"),
  require("plugins.lsp"),
  require("plugins.autocompletion"),
  require("plugins.conform"),
  require("plugins.lint"),
  require("plugins.lualine"),
  {
    "akinsho/bufferline.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
  },
  require("plugins.neotree"),
  require("plugins.snacks"),
  require("plugins.comment"),
  require("plugins.debug"),
  require("plugins.gitsigns"),
  require("plugins.database"),
  require("plugins.misc"),
  require("plugins.harpoon"),
  require("plugins.aerial"),
  require("plugins.flash"),
  require("plugins.vim-tmux-navigator"),
  require("plugins.rust"),
  require("plugins.trouble"),
  require("plugins.grug-far"),
  require("plugins.oil"),
  require("plugins.render-markdown"),
  require("plugins.persistence"),
  require("plugins.claude"),
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
          mini = {
            enabled = true,
            indentscope_color = "",
          },
        },
      })

      -- setup must be called before loading
      vim.cmd.colorscheme("catppuccin-macchiato") -- catppuccin-latte, catppuccin-frappe, catppuccin-macchiato, catppuccin-mocha
    end,
  },
}, {
  ui = {
    -- If you have a Nerd Font, set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
})

-- Session management is handled by persistence.nvim (see plugins/persistence.lua);
-- the old manual `.session.vim` source block was removed in favor of it.

-- Persistent, rolling error/warning log.
-- Required after lazy.setup so the vim.notify wrapper wraps snacks.notifier's replacement.
require("core.logging")

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
require("plugins.bufferline")

vim.opt.spelllang = "en_gb,fr"
