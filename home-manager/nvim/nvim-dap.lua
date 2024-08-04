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
	whichkey.add({
		{ "<localleader>d", desc = "Debugger-related commands" },
		{ "<localleader>do", dap.step_over, desc = "Step over" },
		{ "<localleader>di", dap.step_into, desc = "Step into" },
		{ "<localleader>dc", dap.continue, desc = "Continue" },
		{ "<localleader>dC", dap.run_last, desc = "Run with last debug configuration" },
		{ "<localleader>db", dap.toggle_breakpoint, desc = "Toggle breakpoint" },
		{ "<localleader>dr", dap.repl.open, desc = "Open debug repl" },
		{ "<localleader>dv", desc = "Commands to view debugger state" },
		{
			"<localleader>dvv",
			function()
				dap_ui.hover()
			end,
			desc = "View value of expression under cursor",
		},
		{
			"<localleader>dvs",
			function()
				dap_ui.sidebar(dap_ui.scopes).open()
			end,
			desc = "View values of all variables in all scopes",
		},
		{
			"<localleader>dvf",
			function()
				dap_ui.sidebar(dap_ui.frames).open()
			end,
			desc = "View stack frames",
		},
		{ "<localleader>dt", dap.terminate, desc = "Terminate/stop/end debug session" },
	})
end
