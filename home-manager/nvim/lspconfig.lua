local nvim_cmp = require("cmp")

-- Using rustaceanvim means we shouldn't set up the LSP for Rust manually.
-- Similarly csharp_ls is unnecessary given roslyn.nvim
-- require("lspconfig")["csharp_ls"].setup({})
local schemas = {
	["https://raw.githubusercontent.com/docker/compose/master/compose/config/compose_spec.json"] = "docker-compose*.{yml,yaml}",
	["https://json.schemastore.org/github-workflow.json"] = ".github/**/*.{yml,yaml}",
	["https://json.schemastore.org/package.json"] = "package.json",
	["https://json.schemastore.org/global.json"] = "global.json",
	["https://raw.githubusercontent.com/dotnet/Nerdbank.GitVersioning/master/src/NerdBank.GitVersioning/version.schema.json"] = "version.json",
	["https://json-schema.org/draft/2020-12/schema"] = "*.schema.json",
	["https://json.schemastore.org/dotnet-tools.json"] = "dotnet-tools.json",
}

require("lspconfig")["clangd"].setup({})

require("lspconfig")["gopls"].setup({})

require("lspconfig")["yamlls"].setup({
	settings = {
		yaml = {
			validate = true,
			-- disable the schema store
			schemaStore = {
				enable = false,
				url = "",
			},
			-- manually select schemas
			schemas = schemas,
		},
	},
	filetypes = { "yaml", "json", "jsonc" },
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

capabilities.textDocument.completion.completionItem.snippetSupport = true
require("lspconfig")["jsonls"].setup({
	capabilities = capabilities,
	cmd = { "vscode-json-language-server", "--stdio" },
	settings = {
		json = {
			validate = { enable = true },
		},
	},
})

require("lspconfig")["denols"].setup({})
require("lspconfig")["bashls"].setup({})
require("lspconfig")["dockerls"].setup({})
require("lspconfig")["html"].setup({
	capabilities = capabilities,
})

require("lspconfig")["lua_ls"].setup({
	on_init = function(client)
		if not client.workspace_folders then
			return
		end
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

require("lspconfig").pyright.setup({
	capabilities = capabilities,
	handlers = {
		["textDocument/publishDiagnostics"] = function(...)
			vim.lsp.diagnostic.on_publish_diagnostics(...)

			local window = vim.api.nvim_get_current_win()
			vim.diagnostic.setloclist({ open_loclist = true })
			vim.api.nvim_set_current_win(window)
		end,
	},
})

require("lspconfig").nil_ls.setup({
	capabilities = capabilities,
	settings = {
		nix = {
			flake = {
				autoArchive = true,
			},
		},
	},
})

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
		whichkey.add({
			{ "<leader>l", desc = "loclist-related commands" },
			{ "<leader>lp", vim.diagnostic.goto_prev, desc = "Go to previous entry in loclist" },
			{ "<leader>ln", vim.diagnostic.goto_next, desc = "Go to next entry in loclist" },
			{ "<leader>ll", ToggleLocList, desc = "Toggle loclist" },
			{ "<leader>lf", vim.diagnostic.open_float, desc = "Open current loclist entry in floating window" },
		})
	else
		vim.keymap.set("n", "<leader>lp", vim.diagnostic.goto_prev)
		vim.keymap.set("n", "<leader>ln", vim.diagnostic.goto_next)
		vim.keymap.set("n", "<leader>ll", ToggleLocList)
		vim.keymap.set("n", "<leader>lf", vim.diagnostic.open_float)
	end
end

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		local whichkey = require("which-key")
		-- Enable completion triggered by <c-x><c-o>
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		-- Buffer local mappings.
		-- See `:help vim.lsp.*` for documentation on any of the below functions
		whichkey.add({
			{ "g", desc = "Go-to related commands" },
			{ "gD", vim.lsp.buf.declaration, desc = "Go to declaration" },
			{ "gd", vim.lsp.buf.definition, desc = "Go to definition" },
			{ "gi", vim.lsp.buf.implementation, desc = "Go to implementation" },
			{
				"gr",
				function()
					require("telescope.builtin").lsp_references()
				end,
				desc = "Find references",
			},
			{ "gK", vim.lsp.buf.hover, desc = "Display information about symbol under cursor" },
		})
		whichkey.add({
			{ "<C-k>", vim.lsp.buf.signature_help, desc = "Display signature information about symbol under cursor" },
		})
		whichkey.add({
			{ "<leader>w", desc = "Workspace-related commands" },
			{ "<leader>wa", vim.lsp.buf.add_workspace_folder, desc = "Add a path to the workspace folders list" },
			{ "<leader>wr", vim.lsp.buf.add_workspace_folder, desc = "Remove a path from the workspace folders list" },
			{
				"<leader>wl",
				function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end,
				desc = "Show the workspace folders list",
			},
			{
				"<leader>f",
				function()
					vim.lsp.buf.format({ async = true })
				end,
				desc = "Autoformat",
			},
			{ "<leader>ca", vim.lsp.buf.code_action, desc = "Select a code action" },
			{ "<leader>rn", vim.lsp.buf.rename, desc = "Rename variable" },
			{ "<leader>D", vim.lsp.buf.type_definition, desc = "Go to type definition" },
		})
	end,
})
