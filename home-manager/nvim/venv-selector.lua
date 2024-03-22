local venv_selector = require 'venv-selector'

venv_selector.setup {
  --- other configuration
  changed_venv_hooks = { venv_selector.hooks.pyright },
  name = { "venv", ".venv" },
}

vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Auto select virtualenv Nvim open',
  pattern = '*',
  callback = function()
    local venv = vim.fn.findfile('pyproject.toml', vim.fn.getcwd() .. ';')
    if venv ~= '' then
      require('venv-selector').retrieve_from_cache()
    end
  end,
  once = true,
})
