-- Override for the `pylsp` language server.
-- Merged on top of nvim-lspconfig's bundled lsp/pylsp.lua definition.
-- All linters/formatters are disabled here because Ruff handles them.
return {
	settings = {
		pylsp = {
			plugins = {
				pyflakes = { enabled = false },
				pycodestyle = { enabled = false },
				autopep8 = { enabled = false },
				yapf = { enabled = false },
				mccabe = { enabled = false },
				pylsp_mypy = { enabled = false },
				pylsp_black = { enabled = false },
				pylsp_isort = { enabled = false },
			},
		},
	},
}
