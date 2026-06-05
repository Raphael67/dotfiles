-- Override for the `ruff` language server.
-- Merged on top of nvim-lspconfig's bundled lsp/ruff.lua definition.
--
-- Notes on code actions: https://github.com/astral-sh/ruff-lsp/issues/119#issuecomment-1595628355
-- Get isort like behavior: https://github.com/astral-sh/ruff/issues/8926#issuecomment-1834048218
--
-- The `:RuffAutofix` / `:RuffOrganizeImports` user commands are created natively
-- in the LspAttach handler in lua/plugins/lsp.lua (vim.lsp.config ignores the
-- old lspconfig-framework `commands` field).
return {}
