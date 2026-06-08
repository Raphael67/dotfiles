-- Rust tooling: rustaceanvim drives rust-analyzer itself (do NOT also enable
-- `rust_analyzer` via vim.lsp.enable in lsp.lua -- that would double-attach).
-- crates.nvim manages Cargo.toml dependencies inline.
return {
	{
		"mrcjkb/rustaceanvim",
		version = "^6",
		lazy = false, -- the plugin configures itself on the `rust` filetype
		ft = { "rust" },
		init = function()
			-- Settings live on vim.g.rustaceanvim (read when the plugin attaches).
			-- Ported from the previous lsp/rust_analyzer.lua override.
			vim.g.rustaceanvim = {
				server = {
					default_settings = {
						["rust-analyzer"] = {
							cargo = { features = "all" },
							check = { command = "clippy" },
							checkOnSave = true,
							diagnostics = { experimental = { enable = true } },
						},
					},
					on_attach = function(_, bufnr)
						-- Enable inlay hints for Rust buffers.
						pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })

						local map = function(keys, func, desc)
							vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "Rust: " .. desc })
						end
						-- RustLsp actions (these supplement the global LSP keymaps in lsp.lua).
						map("<leader>ra", function() vim.cmd.RustLsp("codeAction") end, "Code [A]ction")
						map("<leader>rr", function() vim.cmd.RustLsp("runnables") end, "[R]unnables")
						map("<leader>rd", function() vim.cmd.RustLsp("debuggables") end, "[D]ebuggables")
						map("<leader>rm", function() vim.cmd.RustLsp("expandMacro") end, "Expand [M]acro")
						map("<leader>re", function() vim.cmd.RustLsp("explainError") end, "[E]xplain Error")
						map("<leader>rD", function() vim.cmd.RustLsp("openDocs") end, "Open [D]ocs.rs")
						map("<leader>rh", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr }) end, "Toggle Inlay [H]ints")
						map("K", function() vim.cmd.RustLsp({ "hover", "actions" }) end, "Hover Actions")
					end,
				},
			}
		end,
	},
	{
		"saecki/crates.nvim",
		event = { "BufRead Cargo.toml" },
		opts = {
			completion = {
				crates = { enabled = true },
			},
			lsp = {
				enabled = true,
				actions = true,
				completion = true,
				hover = true,
			},
		},
		config = function(_, opts)
			require("crates").setup(opts)
			-- Cargo.toml keymaps (buffer-local via ftplugin-style autocmd).
			vim.api.nvim_create_autocmd("BufRead", {
				group = vim.api.nvim_create_augroup("crates-keymaps", { clear = true }),
				pattern = "Cargo.toml",
				callback = function(ev)
					local crates = require("crates")
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = "Crates: " .. desc })
					end
					map("<leader>ct", crates.toggle, "[T]oggle")
					map("<leader>cr", crates.reload, "[R]eload")
					map("<leader>cv", crates.show_versions_popup, "Show [V]ersions")
					map("<leader>cf", crates.show_features_popup, "Show [F]eatures")
					map("<leader>cu", crates.update_crate, "[U]pdate crate")
					map("<leader>cU", crates.upgrade_crate, "[U]pgrade crate")
					map("<leader>ca", crates.update_all_crates, "Update [A]ll")
					map("<leader>cA", crates.upgrade_all_crates, "Upgrade [A]ll")
				end,
			})
		end,
	},
}
