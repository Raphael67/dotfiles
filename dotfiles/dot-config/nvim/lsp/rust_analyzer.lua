-- Override for the `rust_analyzer` language server.
-- Merged on top of nvim-lspconfig's bundled lsp/rust_analyzer.lua definition.
return {
	settings = {
		["rust-analyzer"] = {
			cargo = {
				features = "all",
			},
			check = {
				command = "clippy",
			},
			diagnostics = {
				experimental = {
					enable = true,
				},
			},
			checkOnSave = true,
		},
	},
}
