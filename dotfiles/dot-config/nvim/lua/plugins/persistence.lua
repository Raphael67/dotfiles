-- persistence.nvim: per-directory session management.
-- Replaces the manual `.session.vim` source block that used to live in init.lua.
return {
	"folke/persistence.nvim",
	event = "BufReadPre",
	opts = {},
	keys = {
		{ "<leader>qs", function() require("persistence").load() end, desc = "Restore Session (cwd)" },
		{ "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
		{ "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
	},
}
