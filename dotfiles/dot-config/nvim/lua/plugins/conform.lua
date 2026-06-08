-- Formatting via conform.nvim (replaces none-ls/null-ls formatting).
--
-- Format-on-save is gated on `vim.g.disable_autoformat` / `vim.b.disable_autoformat`
-- so `<leader>sn` (and `:FormatDisable`) can save without reformatting. Rust is handled
-- by rustaceanvim (rust-analyzer formats on save), so it is intentionally absent here.
return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>F",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = "",
			desc = "[F]ormat buffer",
		},
	},
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			python = { "ruff_organize_imports", "ruff_format" },
			html = { "prettier" },
			json = { "prettier" },
			jsonc = { "prettier" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			javascript = { "prettier" },
			javascriptreact = { "prettier" },
			typescript = { "prettier" },
			typescriptreact = { "prettier" },
			css = { "prettier" },
			go = { "goimports", "gofumpt" },
		},
		formatters = {
			shfmt = {
				prepend_args = { "-i", "4" },
			},
		},
		default_format_opts = {
			lsp_format = "fallback",
		},
		format_on_save = function(bufnr)
			-- Respect the global/per-buffer disable flags (see `<leader>sn`, :FormatDisable).
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return
			end
			return { timeout_ms = 1000, lsp_format = "fallback" }
		end,
	},
	init = function()
		-- Use conform for gq and the formatexpr.
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

		vim.api.nvim_create_user_command("FormatDisable", function(args)
			if args.bang then
				vim.b.disable_autoformat = true -- buffer-local with !
			else
				vim.g.disable_autoformat = true
			end
		end, {
			desc = "Disable format-on-save (use ! for current buffer only)",
			bang = true,
		})

		vim.api.nvim_create_user_command("FormatEnable", function()
			vim.b.disable_autoformat = false
			vim.g.disable_autoformat = false
		end, {
			desc = "Re-enable format-on-save",
		})
	end,
}
