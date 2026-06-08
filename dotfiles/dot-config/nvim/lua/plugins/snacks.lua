-- snacks.nvim: folke's modular QoL toolkit.
--
-- Adopted broadly here in place of noice (removed). Notably this provides the
-- notifier (vim.notify replacement), indent guides (replaces indent-blankline),
-- lazygit (replaces lazygit.nvim), bufdelete (replaces vim-bbye), and vim.ui.input.
-- The picker is intentionally DISABLED — telescope remains the fuzzy finder.
return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		bigfile = { enabled = true },
		quickfile = { enabled = true },
		indent = {
			enabled = true,
			indent = { char = "▏" },
			scope = { enabled = true },
		},
		input = { enabled = true },
		notifier = {
			enabled = true,
			timeout = 3000,
		},
		scope = { enabled = true },
		words = { enabled = true },
		scratch = { enabled = true },
		gitbrowse = { enabled = true },
		lazygit = {
			enabled = true,
			-- transparent floating window, matching the previous lazygit.nvim setup
			win = { style = "lazygit" },
		},
		bufdelete = { enabled = true },
		dashboard = {
			enabled = true,
			preset = {
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{ icon = " ", key = "g", desc = "Grep Text", action = ":Telescope live_grep" },
					{ icon = " ", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
					{ icon = " ", key = "s", desc = "Restore Session", action = ":lua require('persistence').load()" },
					{ icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
			},
		},
		styles = {
			notification = {
				wo = { wrap = true },
			},
		},
	},
	keys = {
		{ "<leader>lg", function() Snacks.lazygit() end, desc = "LazyGit" },
		{ "<leader>gB", function() Snacks.gitbrowse() end, mode = { "n", "v" }, desc = "Git Browse (open in browser)" },
		{ "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
		{ "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
		{ "<leader>nd", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
		{ "<leader>nh", function() Snacks.notifier.show_history() end, desc = "Notification History" },
		{ "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
		{ "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
		{ "<leader>x", function() Snacks.bufdelete() end, desc = "Close Buffer" },
	},
}
