local coq = require("coq")

-- Using rustaceanvim means we shouldn't set up the LSP for Rust manually.
-- Similarly csharp_ls is unnecessary given roslyn.nvim
-- require("lspconfig")["csharp_ls"].setup({})

require("lspconfig")["lua_ls"].setup({
	on_init = function(client)
		local path = client.workspace_folders[1].name
		if vim.uv.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc") then
			return
		end

		client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
			runtime = {
				-- Tell the language server which version of Lua you're using
				-- (most likely LuaJIT in the case of Neovim)
				version = "LuaJIT",
			},
			-- Make the server aware of Neovim runtime files
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME,
					-- Depending on the usage, you might want to add additional paths here.
					-- "${3rd}/luv/library"
					-- "${3rd}/busted/library",
				},
				-- or pull in all of 'runtimepath'. NOTE: this is a lot slower
				-- library = vim.api.nvim_get_runtime_file("", true)
			},
		})
	end,
	settings = {
		Lua = {},
	},
})

require("lspconfig").pyright.setup(coq.lsp_ensure_capabilities({
	handlers = {
		["textDocument/publishDiagnostics"] = function(...)
			vim.lsp.diagnostic.on_publish_diagnostics(...)

			local window = vim.api.nvim_get_current_win()
			vim.diagnostic.setloclist({ open_loclist = true })
			vim.api.nvim_set_current_win(window)
		end,
	},
}))

require("lspconfig").nil_ls.setup(coq.lsp_ensure_capabilities({
	settings = {
		nix = {
			flake = {
				autoArchive = true,
			},
		},
	},
}))

function ToggleLocList()
	local winid = vim.fn.getloclist(0, { winid = 0 }).winid
	if winid == 0 then
		local window = vim.api.nvim_get_current_win()
		vim.cmd.lopen()
		vim.api.nvim_set_current_win(window)
	else
		vim.cmd.lclose()
	end
end

do
	local whichkey_status, whichkey = pcall(require, "which-key")
	if whichkey_status then
		whichkey.register({
			l = {
				name = "loclist-related commands",
				p = { vim.diagnostic.goto_prev, "Go to previous entry in loclist" },
				n = { vim.diagnostic.goto_next, "Go to next entry in loclist" },
				l = { ToggleLocList, "Toggle loclist" },
				f = { vim.diagnostic.open_float, "Open current loclist entry in floating window" },
			},
		}, { prefix = vim.api.nvim_get_var("maplocalleader") })
	else
		vim.keymap.set("n", "<localleader>lp", vim.diagnostic.goto_prev)
		vim.keymap.set("n", "<localleader>ln", vim.diagnostic.goto_next)
		vim.keymap.set("n", "<localleader>ll", ToggleLocList)
		vim.keymap.set("n", "<localleader>lf", vim.diagnostic.open_float)
	end
end

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		local whichkey_status, whichkey = pcall(require, "which-key")
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		local opts = { buffer = ev.buf }
		if whichkey_status then
			whichkey.register({
				g = {
					name = "Go-to related commands",
					D = { vim.lsp.buf.declaration, "Go to declaration" },
					d = { vim.lsp.buf.definition, "Go to definition" },
					i = { vim.lsp.buf.implementation, "Go to implementation" },
					r = {
						function()
							require("telescope.builtin").lsp_references()
						end,
						"Find references",
					},
				},
				K = { vim.lsp.buf.hover, "Display information about symbol under cursor" },
			})
			whichkey.register({
				["<C-k>"] = { vim.lsp.buf.signature_help, "Display signature information about symbol under cursor" },
			})
			whichkey.register({
				w = {
					a = { vim.lsp.buf.add_workspace_folder, "Add a path to the workspace folders list" },
					r = { vim.lsp.buf.add_workspace_folder, "Remove a path from the workspace folders list" },
					l = {
						function()
							print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
						end,
						"Show the workspace folders list",
					},
				},
				f = {
					function()
						vim.lsp.buf.format({ async = true })
					end,
					"Autoformat",
				},
				c = {
					a = { vim.lsp.buf.code_action, "Select a code action" },
				},
				r = {
					n = { vim.lsp.buf.rename, "Rename variable" },
				},
				D = { vim.lsp.buf.type_definition, "Go to type definition" },
			}, { prefix = "<space>" })
		else
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
			vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
			vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
			vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
			vim.keymap.set("n", "<space>wa", vim.lsp.buf.add_workspace_folder, opts)
			vim.keymap.set("n", "<space>wr", vim.lsp.buf.remove_workspace_folder, opts)
			vim.keymap.set("n", "<space>wl", function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end, opts)
			vim.keymap.set("n", "<space>D", vim.lsp.buf.type_definition, opts)
			vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
			vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
			vim.keymap.set("n", "gr", function()
				require("telescope.builtin").lsp_references()
			end, opts)
			vim.keymap.set("n", "<space>f", function()
				vim.lsp.buf.format({ async = true })
			end, opts)
		end
	end,
})
