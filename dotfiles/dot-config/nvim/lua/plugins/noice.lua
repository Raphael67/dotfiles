return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	opts = {
		lsp = {
			-- Override markdown rendering for Treesitter-powered docs
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
			},
			-- Signature help while typing function args
			signature = {
				enabled = true,
				auto_open = { enabled = true },
			},
		},
		presets = {
			bottom_search = true, -- classic bottom cmdline for search
			command_palette = true, -- cmdline and popupmenu together
			long_message_to_split = true, -- long messages go to a split
			lsp_doc_border = true, -- border on hover docs and signature help
		},
		-- Routes to reduce noise
		routes = {
			-- Skip "written" messages
			{ filter = { event = "msg_show", kind = "", find = "written" }, opts = { skip = true } },
			-- Skip search count messages
			{ filter = { event = "msg_show", kind = "search_count" }, opts = { skip = true } },
		},
	},
	keys = {
		{ "<leader>nl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
		{ "<leader>nh", function() require("noice").cmd("history") end, desc = "Noice History" },
		{ "<leader>nd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All Notifications" },
	},
}
