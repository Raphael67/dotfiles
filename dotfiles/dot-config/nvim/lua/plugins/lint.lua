-- Linting via nvim-lint (replaces none-ls/null-ls diagnostics).
--
-- Python linting is already handled by the `ruff` LSP (see lsp.lua), so it is not
-- duplicated here. Linters run on save and when leaving insert mode.
return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			make = { "checkmake" },
			javascript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescript = { "eslint_d" },
			typescriptreact = { "eslint_d" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("nvim-lint", { clear = true })
		vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				-- eslint_d exits non-zero when no config is found; only run when linters exist.
				if next(lint.linters_by_ft[vim.bo.filetype] or {}) ~= nil then
					lint.try_lint()
				end
			end,
		})

		vim.keymap.set("n", "<leader>ll", function()
			lint.try_lint()
		end, { desc = "Trigger [l]inting for current file" })
	end,
}
