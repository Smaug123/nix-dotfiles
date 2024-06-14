require("roslyn").setup({
	on_attach = function(_, _) end,
	capabilities = vim.lsp.protocol.make_client_capabilities(),
})
