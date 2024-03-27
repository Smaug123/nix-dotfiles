require("nvim-lightbulb").setup({
	autocmd = { enabled = true },
	ignore = {
		clients = {
			-- This one is really noisy
			"lua_ls",
		},
	},
})
