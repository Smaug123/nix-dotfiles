vim.g.python3_host_prog = "%PYTHONENV%/bin/python"
vim.opt.mouse = ""
vim.opt.history = 500
vim.opt.background = "dark"

vim.opt.langmenu = "en"

-- Always show current position
vim.opt.ruler = true
vim.opt.number = true

-- A bit of extra margin to the left
vim.opt.foldcolumn = "1"

vim.opt.autoread = true
vim.opt.backup = false
vim.opt.swapfile = false

-- Use spaces instead of tabs
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.opt.hlsearch = true

-- Don't redraw while executing macros
vim.opt.lazyredraw = true

-- Show matching brackets when text indicator is on one of them
vim.opt.showmatch = true
vim.opt.mat = 2

-- Turn off sound
vim.opt.errorbells = false
vim.opt.visualbell = false

vim.api.nvim_set_keymap('n', ';', '<Nop>', { noremap = true })
vim.api.nvim_set_var("maplocalleader", ";")

function MarkdownPreview()
    local temp_file = vim.fn.tempname() .. ".md"
    local file_name = vim.fn.substitute(vim.fn.tolower(vim.fn.expand('%:t')), '\\W', '_', 'g')
    local temp_html = "/tmp/" .. file_name .. "_tmp.html"

    -- Write the current buffer to the temp file
    vim.cmd('write! ' .. temp_file)

    local pandoc_cmd = 'pandoc ' .. temp_file .. ' -o ' .. temp_html

    -- Execute the pandoc command
    vim.fn.system(pandoc_cmd)

    -- Use tmux and lynx to preview the HTML file
    local lynx_cmd = 'tmux split-window -h lynx ' .. temp_html
    vim.fn.jobstart(vim.split(lynx_cmd, ' '), {silent=true})

    -- Delete the temp markdown file
    vim.fn.delete(temp_file, 'rf')
end

function RemoveCarriageReturn()
    vim.cmd("mark m")
    vim.cmd("normal! Hmt")
    vim.cmd("%s/\r//ge")
    vim.cmd("normal! 'tzt'm")
end

function FormatJson()
    local curpos = vim.api.nvim_win_get_cursor(0)
    vim.cmd("%!python -m json.tool")
    vim.api.nvim_win_set_cursor(0, curpos)
end

function ChangeToCurrentDirectory()
    vim.cmd(":cd %:p:h")
    vim.cmd(":pwd")
end

local status, whichkey = pcall(require, "which-key")
if status then
    whichkey.register({
        ["mp"] = {
            MarkdownPreview, "Preview Markdown in Lynx"
        },
        ["md"] = {
            RemoveCarriageReturns, "Delete carriage returns from file"
        },
        ["j"] = {
            FormatJson, "Auto-format JSON"
        },
        ["cd"] = {
            ChangeToCurrentDirectory, "Switch CWD to the directory of the open buffer"
        }
      }, { prefix = vim.api.nvim_get_var("maplocalleader") })
else
  vim.api.nvim_set_keymap('n', '<localleader>mp', ':lua MarkdownPreview()<CR>', { noremap = true, silent = true })
  -- Remove the Windows ^M - when the encodings gets messed up
  vim.api.nvim_set_keymap('n', '<localleader>md', ':lua RemoveCarriageReturn()<CR>', { noremap=true })
  vim.api.nvim_set_keymap('n', '<localleader>j', ':lua FormatJson()<CR>', { noremap=true })
  vim.api.nvim_set_keymap('n', '<localleader>cd', ':lua ChangeToCurrentDirectory()<CR>', { noremap=true })
end

