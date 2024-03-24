local dap = require("dap")
local dap_ui = require("dap.ui.widgets")
dap.adapters.coreclr = {
	type = "executable",
	command = "netcoredbg",
	args = { "--interpreter=vscode", "--", "dotnet" },
}

dap.configurations.fsharp = {
	{
		type = "coreclr",
		name = "launch - netcoredbg",
		request = "launch",
		program = function()
			return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
		end,
	},
}

local status, whichkey = pcall(require, "which-key")
if status then
	whichkey.register({
		d = {
			o = { dap.step_over, "Step over" },
			i = { dap.step_into, "Step into" },
			c = { dap.continue, "Continue" },
			C = { dap.run_last, "Run with last debug configuration" },
			b = { dap.toggle_breakpoint, "Toggle breakpoint" },
			r = { dap.repl.open, "Open debug repl" },
			v = {
				v = {
					function()
						dap_ui.hover()
					end,
					"View value of expression under cursor",
				},
				s = {
					function()
						dap_ui.sidebar(dap_ui.scopes).open()
					end,
					"View values of all variables in all scopes",
				},
				f = {
					function()
						dap_ui.sidebar(dap_ui.frames).open()
					end,
					"View stack frames",
				},
			},
			t = { dap.terminate, "Terminate/stop/end debug session" },
		},
	}, { prefix = vim.api.nvim_get_var("maplocalleader") })
else
	vim.api.nvim_set_keymap("n", "<localleader>do", ":lua require('dap').step_over()<CR>", { noremap = true })
	vim.api.nvim_set_keymap("n", "<localleader>di", ":lua require('dap').step_into()<CR>", { noremap = true })
	vim.api.nvim_set_keymap("n", "<localleader>dc", ":lua require('dap').continue()<CR>", { noremap = true })
	vim.api.nvim_set_keymap("n", "<localleader>dC", ":lua require('dap').run_last()<CR>", { noremap = true })
	vim.api.nvim_set_keymap("n", "<localleader>db", ":lua require('dap').toggle_breakpoint()<CR>", { noremap = true })
	vim.api.nvim_set_keymap("n", "<localleader>dr", ":lua require('dap').repl.open()<CR>", { noremap = true })
	vim.api.nvim_set_keymap("n", "<localleader>dvv", ":lua require('dap.ui.widgets').hover()<CR>", { noremap = true })
	vim.api.nvim_set_keymap(
		"n",
		"<localleader>dvs",
		":lua require('dap.ui.widgets').sidebar(require('dap.ui.widgets').scopes).open()<CR>",
		{ noremap = true }
	)
	vim.api.nvim_set_keymap(
		"n",
		"<localleader>dvf",
		":lua require('dap.ui.widgets').sidebar(require('dap.ui.widgets').frames).open()<CR>",
		{ noremap = true }
	)
	vim.api.nvim_set_keymap("n", "<localleader>dt", ":lua require('dap').terminate()<CR>", { noremap = true })
end
