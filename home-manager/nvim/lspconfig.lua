-- LSP configuration using Neovim 0.11+ native vim.lsp.config API
-- See :help lspconfig-nvim-0.11

local schemas = {
	["https://raw.githubusercontent.com/docker/compose/master/compose/config/compose_spec.json"] = "docker-compose*.{yml,yaml}",
	["https://json.schemastore.org/github-workflow.json"] = ".github/**/*.{yml,yaml}",
	["https://json.schemastore.org/package.json"] = "package.json",
	["https://json.schemastore.org/global.json"] = "global.json",
	["https://raw.githubusercontent.com/dotnet/Nerdbank.GitVersioning/master/src/NerdBank.GitVersioning/version.schema.json"] = "version.json",
	["https://json-schema.org/draft/2020-12/schema"] = "*.schema.json",
	["https://json.schemastore.org/dotnet-tools.json"] = "dotnet-tools.json",
}

-- Configure LSP servers
vim.lsp.config.clangd = {}

vim.lsp.config.gopls = {}

vim.lsp.config.yamlls = {
	settings = {
		yaml = {
			validate = true,
			schemaStore = {
				enable = false,
				url = "",
			},
			schemas = schemas,
		},
	},
	filetypes = { "yaml", "json", "jsonc" },
}

vim.lsp.config.jsonls = {
	cmd = { "vscode-json-language-server", "--stdio" },
	settings = {
		json = {
			validate = { enable = true },
		},
	},
}

vim.lsp.config.denols = {}
vim.lsp.config.bashls = {}
vim.lsp.config.dockerls = {}

vim.lsp.config.html = {}

vim.lsp.config.lua_ls = {
	on_init = function(client)
		if not client.workspace_folders then
			return
		end
		local path = client.workspace_folders[1].name
		if vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc") then
			return
		end

		client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
			runtime = {
				version = "LuaJIT",
			},
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME,
				},
			},
		})
	end,
	settings = {
		Lua = {},
	},
}

vim.lsp.config.pyright = {
	handlers = {
		["textDocument/publishDiagnostics"] = function(err, result, ctx)
			vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx)

			local window = vim.api.nvim_get_current_win()
			vim.diagnostic.setloclist({ open = true })
			vim.api.nvim_set_current_win(window)
		end,
	},
}

vim.lsp.config.nil_ls = {
	settings = {
		nix = {
			flake = {
				autoArchive = true,
			},
		},
	},
}

-- Enable all configured servers
vim.lsp.enable("clangd")
vim.lsp.enable("gopls")
vim.lsp.enable("yamlls")
vim.lsp.enable("jsonls")
vim.lsp.enable("denols")
vim.lsp.enable("bashls")
vim.lsp.enable("dockerls")
vim.lsp.enable("html")
vim.lsp.enable("lua_ls")
vim.lsp.enable("pyright")
vim.lsp.enable("nil_ls")

-- Note: rust-analyzer is managed by rustaceanvim, not configured here
-- Note: csharp_ls is managed by roslyn.nvim, not configured here

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
		local client = vim.lsp.get_client_by_id(ev.data.client_id)

		-- Enable native LSP completion
		if client and client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end

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
			{ "<leader>wr", vim.lsp.buf.remove_workspace_folder, desc = "Remove a path from the workspace folders list" },
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
