local coq = require('coq')

require('lspconfig').pyright.setup(coq.lsp_ensure_capabilities({
    handlers = {
        ["textDocument/publishDiagnostics"] = function(...)
            vim.lsp.diagnostic.on_publish_diagnostics(...)

            local window = vim.api.nvim_get_current_win()
            vim.diagnostic.setloclist({open_loclist = false})
            vim.api.nvim_set_current_win(window)
        end,
    },
}))

require('lspconfig').nil_ls.setup (coq.lsp_ensure_capabilities({
    settings = {
        nix = {
            flake = {
                autoArchive = true,
            },
        },
    },
}))
