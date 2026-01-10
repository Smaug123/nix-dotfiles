-- rustaceanvim configuration
-- Note: rustaceanvim uses vim.g.rustaceanvim for configuration, not a setup() call

-- Paths injected by Nix (see home.nix)
local codelldb_path = "%CODELLDB_PATH%"
local liblldb_path = "%LIBLLDB_PATH%"

-- Fix rustaceanvim's config format issues for codelldb
local function fix_rustaceanvim_config(config)
	-- sourceMap: rustaceanvim generates { { "from", "to" } } but codelldb expects { ["from"] = "to" }
	if config.sourceMap and type(config.sourceMap) == "table" then
		local dominated_by_arrays = false
		for _, v in pairs(config.sourceMap) do
			if type(v) == "table" then
				dominated_by_arrays = true
				break
			end
		end
		if dominated_by_arrays then
			local fixed = {}
			for _, v in ipairs(config.sourceMap) do
				if type(v) == "table" and #v == 2 then
					fixed[v[1]] = v[2]
				end
			end
			config.sourceMap = fixed
		end
	end

	-- env: rustaceanvim generates { "KEY=value" } but codelldb expects { KEY = "value" }
	if config.env and type(config.env) == "table" then
		local first_val = config.env[1]
		if type(first_val) == "string" and first_val:find("=") then
			local fixed = {}
			for _, v in ipairs(config.env) do
				local key, val = v:match("^([^=]+)=(.*)$")
				if key then
					fixed[key] = val
				end
			end
			config.env = fixed
		end
	end

	-- sourceLanguages should be a list of strings, not false
	if config.sourceLanguages == false then
		config.sourceLanguages = { "rust" }
	end

	return config
end

-- Register the codelldb adapter with nvim-dap (for rustaceanvim compatibility)
local dap = require("dap")
dap.adapters.lldb = {
	type = "executable",
	command = codelldb_path,
	args = { "--liblldb", liblldb_path },
	name = "lldb",
	enrich_config = function(config, on_config)
		on_config(fix_rustaceanvim_config(config))
	end,
}
dap.adapters.codelldb = dap.adapters.lldb

vim.g.rustaceanvim = {
	tools = {
		-- Automatically set inlay hints
		inlay_hints = {
			auto = true,
		},
	},
	server = {
		on_attach = function(client, bufnr)
			-- Enable native LSP completion
			if client:supports_method("textDocument/completion") then
				vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
			end
			local whichkey = require("which-key")
			whichkey.add({
				buffer = bufnr,
				{ "<localleader>r", desc = "Rust-specific commands" },
				{
					"<localleader>rr",
					function()
						vim.cmd.RustLsp("runnables")
					end,
					desc = "Run (select runnable)",
				},
				{
					"<localleader>rd",
					function()
						vim.cmd.RustLsp("debuggables")
					end,
					desc = "Debug (select debuggable)",
				},
				{
					"<localleader>rt",
					function()
						vim.cmd.RustLsp("testables")
					end,
					desc = "Test (select testable)",
				},
				{
					"<localleader>re",
					function()
						vim.cmd.RustLsp("expandMacro")
					end,
					desc = "Expand macro recursively",
				},
				{
					"<localleader>rc",
					function()
						vim.cmd.RustLsp("openCargo")
					end,
					desc = "Open Cargo.toml",
				},
				{
					"<localleader>rp",
					function()
						vim.cmd.RustLsp("parentModule")
					end,
					desc = "Go to parent module",
				},
				{
					"<localleader>rj",
					function()
						vim.cmd.RustLsp("joinLines")
					end,
					desc = "Join lines (Rust-aware)",
				},
				{
					"<localleader>ra",
					function()
						vim.cmd.RustLsp("codeAction")
					end,
					desc = "Code actions (Rust-specific)",
				},
				{
					"<localleader>rh",
					function()
						vim.cmd.RustLsp({ "hover", "actions" })
					end,
					desc = "Hover actions",
				},
				{
					"<localleader>rm",
					function()
						vim.cmd.RustLsp({ "moveItem", "up" })
					end,
					desc = "Move item up",
				},
				{
					"<localleader>rM",
					function()
						vim.cmd.RustLsp({ "moveItem", "down" })
					end,
					desc = "Move item down",
				},
				{
					"<localleader>rx",
					function()
						vim.cmd.RustLsp("explainError")
					end,
					desc = "Explain error under cursor",
				},
				{
					"<localleader>rD",
					function()
						vim.cmd.RustLsp("renderDiagnostic")
					end,
					desc = "Render diagnostic (full)",
				},
			})
		end,
		default_settings = {
			["rust-analyzer"] = {
				cargo = {
					allFeatures = true,
					loadOutDirsFromCheck = true,
				},
				check = {
					command = "clippy",
				},
				procMacro = {
					enable = true,
				},
			},
		},
	},
}

-- Clean up rust-analyzer on Neovim exit to prevent zombie processes
vim.api.nvim_create_autocmd("VimLeavePre", {
	pattern = "*",
	callback = function()
		local clients = vim.lsp.get_clients({ name = "rust-analyzer" })
		local pids = {}

		-- Collect PIDs before stopping clients
		for _, client in ipairs(clients) do
			if client.rpc and client.rpc.pid then
				table.insert(pids, client.rpc.pid)
			end
		end

		-- Try graceful shutdown first
		for _, client in ipairs(clients) do
			client.stop(true)
		end

		-- Wait briefly for graceful shutdown
		local graceful = vim.wait(500, function()
			for _, pid in ipairs(pids) do
				-- Check if process still exists (signal 0 = check existence)
				if os.execute("kill -0 " .. pid .. " 2>/dev/null") == 0 then
					return false
				end
			end
			return true
		end, 50)

		-- Force kill if still running
		if not graceful then
			for _, pid in ipairs(pids) do
				os.execute("kill -9 " .. pid .. " 2>/dev/null")
			end
		end
	end,
})
