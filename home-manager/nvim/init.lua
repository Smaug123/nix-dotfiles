vim.g.python3_host_prog = "%PYTHONENV%/bin/python"
vim.opt.mouse = ""
vim.opt.history = 500
vim.opt.background = "dark"

vim.opt.wildmenu = true
vim.opt.wildignore = vim.opt.wildignore + { "*/.git/*", "*/.hg/*", "*/.svn/*", "*/.DS_Store" }

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.magic = true
vim.opt.hlsearch = true

vim.opt.autoindent = true
vim.opt.smartindent = true

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.textwidth = 500

vim.opt.switchbuf = "useopen"

vim.opt.laststatus = 2
-- I don't use tabs, but one day I might!
vim.opt.showtabline = 2

vim.opt.langmenu = "en"

vim.opt.ffs = "unix"
vim.opt.encoding = "utf8"

-- Always show current position
vim.opt.ruler = true
vim.opt.number = true

-- A bit of extra margin to the left
vim.opt.foldcolumn = "1"

vim.opt.autoread = true
vim.opt.backup = false
vim.opt.writebackup = true
vim.opt.swapfile = false

vim.opt.cmdheight = 2

-- Use spaces instead of tabs
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.opt.lazyredraw = true

-- Show matching brackets when text indicator is on one of them
vim.opt.showmatch = true
vim.opt.mat = 2

-- Turn off sound
vim.opt.errorbells = false
vim.opt.visualbell = false

vim.opt.timeoutlen = 500

vim.opt.scrolloff = 2

-- Return to last edit position when opening files
vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*",
	callback = function()
		local line = vim.fn.line
		local last_pos = line("'\"")
		if last_pos > 1 and last_pos <= line("$") then
			vim.cmd("normal! g'\"")
		end
	end,
})

-- Trim trailing whitespace on save
function CleanExtraSpaces()
	local save_cursor = vim.api.nvim_win_get_cursor(0)
	local old_query = vim.fn.getreg("/")
	vim.cmd("%s/\\s\\+$//e")
	vim.api.nvim_win_set_cursor(0, save_cursor)
	vim.fn.setreg("/", old_query)
end
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.fs", "*.fsi", "*.txt", "*.js", "*.py", "*.wiki", "*.sh", "*.coffee" },
	callback = CleanExtraSpaces,
})

-- Status line

-- Returns true if paste mode is enabled
function HasPaste()
	if vim.opt.paste:get() then
		return "PASTE MODE  "
	end
	return ""
end

vim.o.statusline = vim.o.statusline .. "%{v:lua.HasPaste()}%F%m%r%h %w  Line: %l  Column: %c"

--------------------------------------------------------------

vim.api.nvim_set_keymap("n", ";", "<Nop>", { noremap = true })
vim.api.nvim_set_var("maplocalleader", ";")
vim.api.nvim_set_var("mapleader", " ")

function MarkdownPreview()
	local temp_file = vim.fn.tempname() .. ".md"
	local file_name = vim.fn.substitute(vim.fn.tolower(vim.fn.expand("%:t")), "\\W", "_", "g")
	local temp_html = "/tmp/" .. file_name .. "_tmp.html"

	-- Write the current buffer to the temp file
	vim.cmd("write! " .. temp_file)

	local pandoc_cmd = "pandoc " .. temp_file .. " -o " .. temp_html

	-- Execute the pandoc command
	vim.fn.system(pandoc_cmd)

	-- Use tmux and lynx to preview the HTML file
	local lynx_cmd = "tmux split-window -h lynx " .. temp_html
	vim.fn.jobstart(vim.split(lynx_cmd, " "), { silent = true })

	-- Delete the temp markdown file
	vim.fn.delete(temp_file, "rf")
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

local function close_loclist_if_orphaned()
	local win = vim.fn.expand("<afile>")
	vim.fn.win_execute(win, "lclose")
end

-- Set up an autocmd using the nvim_create_autocmd API
vim.api.nvim_create_autocmd("WinClosed", {
	pattern = "*",
	callback = close_loclist_if_orphaned,
})

local whichkey = require("which-key")
local pickers = require("telescope.pickers")
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

function DisplayAllMappingsWithTelescope()
	local mappings = {}
	local commands = {} -- Store commands keyed by the display string

	local function accumulate(tree)
		tree:walk(function(node)
			-- Note: we could (if desired) view all groups, because the `node.mapping` table looks like this:
			-- { prefix = "g", group = true, keys = {...}}
			if node.mapping then
				local mapping = node.mapping
				if not mapping.group then
					local description = mapping.desc or mapping.label or mapping.cmd
					-- Some actions are just there for which-key to hook into to display prefixes; they don't have a description.
					if description then
						local displayString = description .. " | " .. mapping.prefix
						commands[displayString] = mapping.prefix
						mappings[#mappings + 1] = displayString
					else
						for k, v in pairs(mapping) do
							print("Nothing: " .. k .. " : " .. tostring(v) .. " (type: " .. type(v) .. ")")
						end
						print("-----")
					end
				end
			end
		end)
	end

	local cur_buf = vim.api.nvim_win_get_buf(0)

	accumulate(require("which-key.keys").get_tree("n").tree)
	accumulate(require("which-key.keys").get_tree("n", cur_buf).tree)

	pickers
		.new({}, {
			prompt_title = "Actions",
			finder = finders.new_table({
				results = mappings,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(bufnr)
					local selection = action_state.get_selected_entry()
					actions.close(bufnr)
					local cmd = commands[selection.value]
					if cmd then
						vim.api.nvim_command(":normal " .. vim.api.nvim_replace_termcodes(cmd, true, true, true))
					else
						print("no command found")
					end
				end)
				return true
			end,
		})
		:find()
end

function ToggleSpell()
	vim.cmd("setlocal spell!")
end

whichkey.register({
	[vim.api.nvim_get_var("maplocalleader")] = {
		DisplayAllMappingsWithTelescope,
		"View all mappings",
	},
	m = {
		p = { MarkdownPreview, "Preview Markdown in Lynx" },
		d = { RemoveCarriageReturn, "Delete carriage returns from file" },
	},
	["j"] = {
		FormatJson,
		"Auto-format JSON",
	},
}, { prefix = vim.api.nvim_get_var("maplocalleader") })
whichkey.register({
	g = {
		function()
			require("telescope.builtin").grep_string()
		end,
		"Find instances of text under cursor",
	},
	h = {
		name = "Find historical...",
		f = {
			function()
				require("telescope.builtin").oldfiles()
			end,
			"List previously open files",
		},
		c = {
			function()
				require("telescope.builtin").command_history()
			end,
			"List previously run commands",
		},
		s = {
			function()
				require("telescope.builtin").search_history()
			end,
			"List previously run searches",
		},
	},
	m = {
		function()
			require("telescope.builtin").marks()
		end,
		"List marks",
	},
	["cd"] = {
		ChangeToCurrentDirectory,
		"Switch CWD to the directory of the open buffer",
	},
	["ss"] = {
		ToggleSpell,
		"Toggle spell-checker on or off",
	},
	[vim.api.nvim_get_var("mapleader")] = {
		function()
			require("telescope.builtin").find_files()
		end,
		"Find files by name",
	},
}, { prefix = vim.api.nvim_get_var("mapleader") })
