require("lspconfig")["leanls"].setup({})

require("lean").setup({})

require("which-key").add({
	{ "<localleader>l", desc = "Lean" },
	{ "<localleader>li", "<Cmd>LeanInfoviewToggle<CR>", desc = "Toggle Lean info view" },
	{ "<localleader>lp", "<Cmd>LeanInfoviewPinTogglePause<CR>", desc = "Pause Lean info view" },
	{ "<localleader>ls", "<Cmd>LeanSorryFill<CR>", desc = "Fill open goals with sorry" },
	{ "<localleader>lw", "<Cmd>LeanInfoviewEnableWidgets<CR>", desc = "Enable Lean widgets" },
	{ "<localleader>lW", "<Cmd>LeanInfoviewDisableWidgets<CR>", desc = "Disable Lean widgets" },
	{
		"<localleader>l?",
		"<Cmd>LeanAbbreviationsReverseLookup<CR>",
		desc = "Show what Lean abbreviation produces the symbol under the cursor",
	},
})
