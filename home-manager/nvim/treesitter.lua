-- nvim-treesitter 1.0+ removed the configs module
-- Highlighting is now handled by Neovim's built-in treesitter support
-- Parsers are installed via Nix (withAllGrammars in home.nix)

-- Enable treesitter-based highlighting for all buffers with a parser
vim.api.nvim_create_autocmd("FileType", {
	callback = function()
		pcall(vim.treesitter.start)
	end,
})
