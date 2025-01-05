return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",

      -- see below for full list of optional dependencies 👇
  },
  config = function()
    require('obsidian').setup {


          workspaces = {
          {
              name = "personal",
              path = "/Users/raphael/Library/Mobile Documents/iCloud~md~obsidian",
          },
          },

          -- see below for full list of options 👇

    }
  end,
}

