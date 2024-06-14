local dap = require("dap")
local dap_ui = require("dap.ui.widgets")
dap.adapters.coreclr = {
	type = "executable",
	command = "netcoredbg",
	args = { "--interpreter=vscode" },
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

dap.configurations.cs = {
	{
		type = "coreclr",
		name = "launch - netcoredbg",
		request = "launch",
		program = function()
			return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
		end,
	},
}

do
	local whichkey = require("which-key")
	whichkey.register({
		d = {
			name = "Debugger-related commands",
			o = { dap.step_over, "Step over" },
			i = { dap.step_into, "Step into" },
			c = { dap.continue, "Continue" },
			C = { dap.run_last, "Run with last debug configuration" },
			b = { dap.toggle_breakpoint, "Toggle breakpoint" },
			r = { dap.repl.open, "Open debug repl" },
			v = {
				name = "Commands to view debugger state",
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
end
