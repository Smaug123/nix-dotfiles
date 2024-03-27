require("lspconfig")["leanls"].setup({})

require("lean").setup({})

require("which-key").register({
	l = {
		i = { "<Cmd>LeanInfoviewToggle<CR>", "Toggle Lean info view" },
		p = { "<Cmd>LeanInfoviewPinTogglePause<CR>", "Pause Lean info view" },
		s = { "<Cmd>LeanSorryFill<CR>", "Fill open goals with sorry" },
		w = { "<Cmd>LeanInfoviewEnableWidgets<CR>", "Enable Lean widgets" },
		W = { "<Cmd>LeanInfoviewDisableWidgets<CR>", "Disable Lean widgets" },
		["?"] = {
			"<Cmd>LeanAbbreviationsReverseLookup<CR>",
			"Show what Lean abbreviation produces the symbol under the cursor",
		},
	},
}, { prefix = vim.api.nvim_get_var("maplocalleader") })
