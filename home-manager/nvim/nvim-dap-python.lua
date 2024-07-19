require("dap-python").setup("%PYTHONENV%/bin/python")

do
	local whichkey = require("which-key")
	whichkey.register({
		["pd"] = {
			"Debugger-related commands",
			t = {
				"Tests",
				f = { require("dap-python").test_class, "Run Python tests in the current file" },
				c = { require("dap-python").test_method, "Run the Python test under the cursor" },
			},
		},
	}, { prefix = vim.api.nvim_get_var("maplocalleader") })
end
