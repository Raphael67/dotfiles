-- render-markdown.nvim: in-buffer rendering of markdown (headings, code blocks, etc.).
return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"echasnovski/mini.icons",
	},
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {},
}
