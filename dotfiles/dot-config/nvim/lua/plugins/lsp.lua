return { -- LSP Configuration & Plugins
	"neovim/nvim-lspconfig",
	dependencies = {
		-- Automatically install LSPs and related tools to stdpath for neovim
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"saghen/blink.cmp",

		-- Useful status updates for LSP.
		-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
		{
			"j-hui/fidget.nvim",
			version = "v1.*", -- track latest 1.x release (auto-updates with :Lazy update)
			opts = {
				progress = {
					display = {
						done_icon = "✓", -- Icon shown when all LSP progress tasks are complete
					},
				},
				notification = {
					window = {
						winblend = 0, -- Background color opacity in the notification window
					},
				},
			},
		},
	},
	config = function()
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
			-- Create a function that lets us more easily define mappings specific LSP related items.
			-- It sets the mode, buffer and description for us each time.
			callback = function(event)
				local map = function(keys, func, desc)
					vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end

				-- Jump to the definition of the word under your cursor.
				--  This is where a variable was first declared, or where a function is defined, etc.
				--  To jump back, press <C-T>.
				map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

				-- Find references for the word under your cursor.
				map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

				-- Jump to the implementation of the word under your cursor.
				--  Useful when your language has ways of declaring types without an actual implementation.
				map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

				-- Jump to the type of the word under your cursor.
				--  Useful when you're not sure what type a variable is and you want to see
				--  the definition of its *type*, not where it was *defined*.
				map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

				-- Fuzzy find all the symbols in your current document.
				--  Symbols are things like variables, functions, types, etc.
				map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

				-- Fuzzy find all the symbols in your current workspace
				--  Similar to document symbols, except searches over your whole project.
				map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

				-- Rename the variable under your cursor
				--  Most Language Servers support renaming across files, etc.
				map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

				-- Execute a code action, usually your cursor needs to be on top of an error
				-- or a suggestion from your LSP for this to activate.
				map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

				-- Opens a popup that displays documentation about the word under your cursor
				--  See `:help K` for why this keymap
				map("K", vim.lsp.buf.hover, "Hover Documentation")

				-- WARN: This is not Goto Definition, this is Goto Declaration.
				--  For example, in C this would take you to the header
				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

				map("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
				map("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
				map("<leader>wl", function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, "[W]orkspace [L]ist Folders")

				-- The following two autocommands are used to highlight references of the
				-- word under your cursor when your cursor rests there for a little while.
				--    See `:help CursorHold` for information about when this is executed
				--
				-- When you move your cursor, the highlights will be cleared (the second autocommand).
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if client and client:supports_method("textDocument/documentHighlight") then
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = event.buf,
						callback = vim.lsp.buf.document_highlight,
					})

					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = event.buf,
						callback = vim.lsp.buf.clear_references,
					})
				end

				-- Ruff: recreate the helper commands natively (the lspconfig-framework
				-- `commands` field is ignored by vim.lsp.config). `client:exec_cmd` is
				-- the 0.12 replacement for the deprecated `vim.lsp.buf.execute_command`.
				if client and client.name == "ruff" then
					vim.api.nvim_buf_create_user_command(event.buf, "RuffAutofix", function()
						client:exec_cmd({
							command = "ruff.applyAutofix",
							arguments = { { uri = vim.uri_from_bufnr(event.buf) } },
						})
					end, { desc = "Ruff: Fix all auto-fixable problems" })

					vim.api.nvim_buf_create_user_command(event.buf, "RuffOrganizeImports", function()
						client:exec_cmd({
							command = "ruff.applyOrganizeImports",
							arguments = { { uri = vim.uri_from_bufnr(event.buf) } },
						})
					end, { desc = "Ruff: Format imports" })
				end
			end,
		})

		-- Native LSP (Neovim 0.12): nvim-lspconfig ships the catalog of server
		-- definitions under its `lsp/` runtime dir. Per-server overrides live in
		-- this config's own `lsp/<name>.lua` files (auto-discovered on the
		-- runtimepath and deep-merged on top of the lspconfig defaults). Here we
		-- just declare which servers to install + enable.
		--
		-- See `:help lspconfig-all` for the list of pre-configured servers.
		local servers = {
			"html",
			"ts_ls",
			"lua_ls",
			"dockerls",
			"docker_compose_language_service",
			"pylsp",
			"ruff",
			"rust_analyzer",
			"tailwindcss",
			"jsonls",
			"sqlls",
			"terraformls",
			"yamlls",
			"bashls",
			"graphql",
			"cssls",
			"ltex",
			"texlab",
		}

		-- Global capabilities for every server (blink.cmp completion). The
		-- per-server `lsp/<name>.lua` files merge on top of this baseline.
		vim.lsp.config("*", {
			capabilities = require("blink.cmp").get_lsp_capabilities(),
		})

		-- Mason: install the server binaries + extra tools.
		require("mason").setup()

		-- mason-lspconfig is kept installed but PASSIVE: `automatic_enable = false`
		-- so it never enables servers itself (that double-attached every server
		-- alongside our own enable). We keep it only so mason-tool-installer can
		-- translate lspconfig names (e.g. `lua_ls` -> `lua-language-server`).
		require("mason-lspconfig").setup({ automatic_enable = false })

		-- You can add other tools here that you want Mason to install
		-- for you, so that they are available from within Neovim.
		local ensure_installed = vim.deepcopy(servers)
		vim.list_extend(ensure_installed, {
			"stylua", -- Used to format lua code
		})
		require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

		-- Activate exactly the servers listed above. Explicit and visible —
		-- no auto-enable magic. Overrides come from the `lsp/<name>.lua` files.
		vim.lsp.enable(servers)
	end,
}
