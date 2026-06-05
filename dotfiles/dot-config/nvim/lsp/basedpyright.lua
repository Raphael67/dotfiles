-- Override for the `basedpyright` language server.
-- NOT ENABLED: `basedpyright` is absent from the `servers` list in
-- lua/plugins/lsp.lua, so this file is never read. Add "basedpyright" to that
-- list to activate it (and remove `pylsp` if you switch off it).
--
-- Config options: https://github.com/DetachHead/basedpyright/blob/main/docs/settings.md
return {
	settings = {
		basedpyright = {
			disableOrganizeImports = true, -- Using Ruff's import organizer
			disableLanguageServices = false,
			analysis = {
				ignore = { "*" }, -- Ignore all files for analysis to exclusively use Ruff for linting
				typeCheckingMode = "off",
				diagnosticMode = "openFilesOnly", -- Only analyze open files
				useLibraryCodeForTypes = true,
				autoImportCompletions = true, -- whether pyright offers auto-import completions
			},
		},
	},
}
