vim.g.chadtree_settings = { xdg = true }

vim.api.nvim_create_autocmd("VimEnter", {
	pattern = "*",
	command = "CHADopen --nofocus",
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*",
	callback = function()
		vim.schedule(function()
			if vim.fn.winnr("$") == 1 and vim.bo.filetype == "CHADTree" then
				vim.cmd("quit")
			end
		end)
	end,
})

-- Variable to store the CHADtree window ID
local chadtree_winid_and_buf = nil

-- Function to check if a window is displaying CHADtree
local function is_chadtree_window(winid)
	local bufnr = vim.api.nvim_win_get_buf(winid)
	local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
	return filetype == "CHADTree"
end

-- Function to find and store the CHADtree window ID
local function find_chadtree_window()
	for _, winid in ipairs(vim.api.nvim_list_wins()) do
		if is_chadtree_window(winid) then
			chadtree_winid_and_buf = { winid, vim.api.nvim_win_get_buf(winid) }
			break
		end
	end
end

-- Function to switch to CHADtree buffer in the CHADtree window
local function switch_to_chadtree()
	if chadtree_winid_and_buf and vim.api.nvim_win_is_valid(chadtree_winid_and_buf[1]) then
		local current_winid = vim.api.nvim_get_current_win()
		if current_winid == chadtree_winid_and_buf[1] and not is_chadtree_window(current_winid) then
			print("CHADtree window may only point to CHADtree")
			vim.api.nvim_win_set_buf(chadtree_winid_and_buf[1], chadtree_winid_and_buf[2])
		end
	end
end

-- Autocommand to find the CHADtree window after startup
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		vim.defer_fn(find_chadtree_window, 500)
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	callback = switch_to_chadtree,
})
