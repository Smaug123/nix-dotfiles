require("tokyonight").setup({
	style = "night",
	on_colors = function(colors)
		colors.border = "#565f89"
	end,
})

vim.cmd([[colorscheme tokyonight]])
