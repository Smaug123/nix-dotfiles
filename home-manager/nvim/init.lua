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
    vim.cmd("%!python -m json.tool")
end

function ChangeToCurrentDirectory()
    vim.cmd(":cd %:p:h")
    vim.cmd(":pwd")
end

local status, whichkey = pcall(require, "which-key")
if status then
    local telescope = require('telescope')
    local pickers = require('telescope.pickers')
    local action_state = require('telescope.actions.state')
    local actions = require('telescope.actions')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values

    function DisplayAllMappingsWithTelescope()
        local mappings = {}
        local commands = {} -- Store commands keyed by the display string

        require('which-key.keys').get_tree('n').tree:walk(function(node)
            if node.mapping then
                local mapping = node.mapping
                -- for key, value in pairs(mapping) do
                --     print('Key: ' .. key)
                -- end
                local description = mapping.desc or mapping.label or mapping.cmd or "No description"
                local displayString = description .. " | " .. mapping.prefix
                commands[displayString] = mapping.prefix
                mappings[#mappings + 1] = displayString
            end
        end)

        pickers.new({}, {
            prompt_title = "Actions",
            finder = finders.new_table({
                results = mappings,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(_, map)
                map('i', '<CR>', function(bufnr)
                    local selection = action_state.get_selected_entry()
                    actions.close(bufnr)
                    local cmd = commands[selection.value]
                    if cmd then
                        vim.api.nvim_command(":normal " .. vim.api.nvim_replace_termcodes(cmd, true, true, true))
                        -- vim.api.nvim_feedkeys(cmd, 'n', false)
                    else
                        print("no command found")
                    end
                end)
                return true
            end
        }):find()
    end

    vim.api.nvim_set_keymap('n', '<localleader>s', ':lua DisplayAllMappingsWithTelescope()<CR>', {})
    whichkey.register({
        ["mp"] = {
            MarkdownPreview, "Preview Markdown in Lynx"
        },
        ["md"] = {
            RemoveCarriageReturn, "Delete carriage returns from file"
        },
        ["j"] = {
            FormatJson, "Auto-format JSON"
        },
        ["cd"] = {
            ChangeToCurrentDirectory, "Switch CWD to the directory of the open buffer"
        },
        -- For some reason the command doesn't work at all if I map it in here,
        -- whereas if we map it separately and *document* it in here then only the documentation doesn't work.
        ["s"] = {
            "View all mappings"
        },
      }, { prefix = vim.api.nvim_get_var("maplocalleader") })
else
  vim.api.nvim_set_keymap('n', '<localleader>mp', ':lua MarkdownPreview()<CR>', { noremap = true, silent = true })
  -- Remove the Windows ^M - when the encodings gets messed up
  vim.api.nvim_set_keymap('n', '<localleader>md', ':lua RemoveCarriageReturn()<CR>', { noremap=true })
  vim.api.nvim_set_keymap('n', '<localleader>j', ':lua FormatJson()<CR>', { noremap=true })
  vim.api.nvim_set_keymap('n', '<localleader>cd', ':lua ChangeToCurrentDirectory()<CR>', { noremap=true })
end

