-- oil.nvim: edit the filesystem like a normal buffer (great for bulk renames).
-- Complements neo-tree (which stays as the sidebar tree). `-` opens the parent dir.
return {
	"stevearc/oil.nvim",
	lazy = false, -- needed so `oil` can hijack directory buffers (e.g. `nvim .`)
	dependencies = { "echasnovski/mini.icons" },
	opts = {
		default_file_explorer = false, -- keep netrw-style behavior; neo-tree is primary
		view_options = {
			show_hidden = true,
		},
		keymaps = {
			["q"] = "actions.close",
		},
	},
	keys = {
		{ "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
	},
}
