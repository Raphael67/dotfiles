-- Standalone plugins with less than 10 lines of config go here
return {
	{
		-- autoclose tags
		"windwp/nvim-ts-autotag",
	},
	{
		-- detect tabstop and shiftwidth automatically
		"tpope/vim-sleuth",
	},
	{
		-- Powerful Git integration for Vim
		"tpope/vim-fugitive",
	},
	{
		-- GitHub integration for vim-fugitive
		"tpope/vim-rhubarb",
	},
	{
		-- Hints keybinds
		"folke/which-key.nvim",
		opts = {
			-- win = {
			--   border = {
			--     { '┌', 'FloatBorder' },
			--     { '─', 'FloatBorder' },
			--     { '┐', 'FloatBorder' },
			--     { '│', 'FloatBorder' },
			--     { '┘', 'FloatBorder' },
			--     { '─', 'FloatBorder' },
			--     { '└', 'FloatBorder' },
			--     { '│', 'FloatBorder' },
			--   },
			-- },
		},
	},
	{
		-- Autoclose parentheses, brackets, quotes, etc. (mini.* ecosystem, replaces nvim-autopairs)
		"echasnovski/mini.pairs",
		version = "*",
		event = "InsertEnter",
		opts = {},
	},
	{
		-- Treesitter-aware commentstring for embedded languages (JSX/Vue/etc.).
		-- Comment.nvim still provides the toggle keymaps; this fixes the comment string.
		"folke/ts-comments.nvim",
		event = "VeryLazy",
		opts = {},
	},
	{
		-- Highlight todo, notes, etc in comments
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},
	{
		-- high-performance color highlighter
		-- maintained fork of the abandoned norcalli/nvim-colorizer.lua
		-- (the original's final commit still calls deprecated vim.tbl_flatten on nvim 0.11+)
		"catgoose/nvim-colorizer.lua",
		event = "BufReadPre",
		config = function()
			require("colorizer").setup()
		end,
	},
	{
		"echasnovski/mini.icons",
		opts = {},
		lazy = true,
		specs = {
			{ "nvim-tree/nvim-web-devicons", enabled = false, optional = true },
		},
		init = function()
			package.preload["nvim-web-devicons"] = function()
				require("mini.icons").mock_nvim_web_devicons()
				return package.loaded["nvim-web-devicons"]
			end
		end,
	},
	{
		-- Surround actions (add, delete, replace)
		"echasnovski/mini.surround",
		version = "*",
		opts = {},
	},
	{
		-- Enhanced a/i text objects (treesitter-backed function/argument objects)
		"echasnovski/mini.ai",
		version = "*",
		event = "VeryLazy",
		opts = function()
			local ai = require("mini.ai")
			return {
				n_lines = 500,
				custom_textobjects = {
					-- treesitter-powered: af/if functions, ac/ic classes
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
				},
			}
		end,
	},
	{
		"ThePrimeagen/vim-be-good",
	},
	{
		"mbbill/undotree",
		config = function()
			vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
		end,
	},
}
