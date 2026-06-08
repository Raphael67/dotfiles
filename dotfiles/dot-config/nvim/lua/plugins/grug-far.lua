-- grug-far.nvim: project-wide find & replace with a live preview buffer.
-- Bound to <leader>sR to avoid clashing with telescope's <leader>sr (resume).
return {
	"MagicDuck/grug-far.nvim",
	cmd = "GrugFar",
	opts = {},
	keys = {
		{
			"<leader>sR",
			function()
				require("grug-far").open()
			end,
			mode = { "n", "v" },
			desc = "Search & [R]eplace (grug-far)",
		},
	},
}
