require("dap-python").setup("%PYTHONENV%/bin/python")

do
	local whichkey = require("which-key")
	whichkey.add({
		{ "<localleader>pd", desc = "Debugger-related commands" },
		{ "<localleader>pdt", desc = "Tests" },
		{ "<localleader>pdtf", require("dap-python").test_class, desc = "Run Python tests in the current file" },
		{ "<localleader>pdtc", require("dap-python").test_method, desc = "Run the Python test under the cursor" },
	})
end
