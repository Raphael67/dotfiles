-- Highlight, edit, and navigate code (nvim-treesitter `main` branch — requires Neovim 0.12+)
local ensure_installed = {
	"lua",
	"python",
	"javascript",
	"typescript",
	"tsx",
	"regex",
	"sql",
	"dockerfile",
	"toml",
	"json",
	"java",
	"go",
	"gitignore",
	"yaml",
	"markdown",
	"markdown_inline",
	"bash",
	"css",
	"html",
}

return {
	{
		-- NOTE: nvim-treesitter was archived (read-only) on 2026-04-03. The `main`
		-- branch still works on Neovim 0.12+ but receives no further updates, so we
		-- pin it to a known-good commit. Revisit when Neovim core ships an official
		-- parser-management story.
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		commit = "4916d6592ede8c07973490d9322f187e07dfefac",
		pin = true, -- archived upstream; never auto-update
		lazy = false, -- the `main` branch does not support lazy-loading
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup()

			-- Install any parsers that aren't present yet (replaces the old
			-- `ensure_installed` / `auto_install` options, which `main` dropped).
			local installed = require("nvim-treesitter.config").get_installed()
			local to_install = vim.iter(ensure_installed)
				:filter(function(parser)
					return not vim.tbl_contains(installed, parser)
				end)
				:totable()
			if #to_install > 0 then
				require("nvim-treesitter").install(to_install)
			end

			-- Register additional file extensions
			vim.filetype.add({ extension = { tf = "terraform" } })
			vim.filetype.add({ extension = { tfvars = "terraform" } })
			vim.filetype.add({ extension = { pipeline = "groovy" } })
			vim.filetype.add({ extension = { multibranch = "groovy" } })

			-- Enable per-buffer features on FileType (replaces the old
			-- `highlight`/`indent` module options).
			vim.api.nvim_create_autocmd("FileType", {
				pattern = ensure_installed,
				callback = function()
					-- Highlighting (Neovim built-in)
					pcall(vim.treesitter.start)
					-- Indentation (experimental on `main`)
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		commit = "851e865342e5a4cb1ae23d31caf6e991e1c99f1e",
		pin = true, -- archived upstream; never auto-update
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("nvim-treesitter-textobjects").setup({
				select = {
					lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
				},
				move = {
					set_jumps = true, -- whether to set jumps in the jumplist
				},
			})

			local select = require("nvim-treesitter-textobjects.select")
			local swap = require("nvim-treesitter-textobjects.swap")
			local move = require("nvim-treesitter-textobjects.move")

			-- Select (matches the previous aa/ia/af/if/ac/ic mappings)
			local selections = {
				aa = "@parameter.outer",
				ia = "@parameter.inner",
				af = "@function.outer",
				["if"] = "@function.inner",
				ac = "@class.outer",
				ic = "@class.inner",
			}
			for lhs, capture in pairs(selections) do
				vim.keymap.set({ "x", "o" }, lhs, function()
					select.select_textobject(capture, "textobjects")
				end)
			end

			-- Swap
			vim.keymap.set("n", "<leader>a", function()
				swap.swap_next("@parameter.inner")
			end)
			vim.keymap.set("n", "<leader>A", function()
				swap.swap_previous("@parameter.inner")
			end)

			-- Move
			vim.keymap.set({ "n", "x", "o" }, "]m", function()
				move.goto_next_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]]", function()
				move.goto_next_start("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]M", function()
				move.goto_next_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "][", function()
				move.goto_next_end("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[m", function()
				move.goto_previous_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[[", function()
				move.goto_previous_start("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[M", function()
				move.goto_previous_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[]", function()
				move.goto_previous_end("@class.outer", "textobjects")
			end)
		end,
	},
}
