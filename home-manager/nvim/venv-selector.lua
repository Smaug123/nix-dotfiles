local venv_selector = require("venv-selector")

venv_selector.setup({
	changed_venv_hooks = { venv_selector.hooks.pyright },
	name = { "venv", ".venv" },
})

vim.api.nvim_create_autocmd("VimEnter", {
	desc = "Auto select virtualenv Nvim open",
	pattern = "*",
	callback = function()
		-- Mystery: this seems to be being called twice whenever we open nvim
		local venv = vim.fn.findfile("pyproject.toml", vim.fn.getcwd() .. ";")
		if venv ~= "" then
			require("venv-selector").retrieve_from_cache()
		end
	end,
	once = true,
})

function SelectVenv()
	local old_path = vim.fn.getenv("PATH")
	vim.cmd("VenvSelectCached")
	local new_path = vim.fn.getenv("PATH")
	if old_path == new_path then
		-- Failed to source venv. Get the user to choose one.
		vim.cmd("VenvSelect")
	end
end

local function find_requirements_txt(start_path)
	local path = vim.fn.fnamemodify(start_path, ":p")
	while path and #path > 1 do
		local req_path = path .. "requirements.txt"
		if vim.fn.filereadable(req_path) ~= 0 then
			return req_path
		end
		path = vim.fn.fnamemodify(path, ":h")
	end
	return nil
end

-- TODO: make this one work
local function load_venv(venv_dir)
	require("venv-selector.venv").load()
	require("venv-selector.venv").set_venv_and_system_paths(venv_dir)
	require("venv-selector.venv").cache_venv(venv_dir)
end

function CreateVenv()
	local requirements_path = find_requirements_txt(vim.fn.getcwd())
	local venv_dir
	if not requirements_path then
		print("requirements.txt not found; creating fresh venv in current working directory.")
		venv_dir = vim.fn.getcwd() .. "/.venv"
	else
		venv_dir = vim.fn.fnamemodify(requirements_path, ":h") .. "/.venv"
	end

	print("Creating virtual environment in " .. venv_dir)

	-- Create virtual environment
	vim.fn.system("python -m venv " .. vim.fn.shellescape(venv_dir))

	-- Install requirements
	if requirements_path then
		print("Installing requirements from " .. requirements_path)
		local handle
		local stdout = vim.uv.new_pipe(false)
		local stderr = vim.uv.new_pipe(false)

		local function on_output(context, prefix, err, data)
			if err or data then
				vim.schedule(function()
					if err then
						-- Append the error message to the buffer
						local count = vim.api.nvim_buf_line_count(context.buf)
						vim.api.nvim_buf_set_lines(
							context.buf,
							count,
							count,
							false,
							{ "error " .. prefix .. ": " .. err }
						)
					end
					if data then
						-- Append the data to the buffer
						local count = vim.api.nvim_buf_line_count(context.buf)
						vim.api.nvim_buf_set_lines(
							context.buf,
							count,
							count,
							false,
							vim.tbl_map(function(line)
								return prefix .. ": " .. line
							end, vim.split(data, "\n"))
						)
					end
					if vim.api.nvim_win_is_valid(context.window) then
						local cur_win = vim.api.nvim_get_current_win()
						local cur_buf = vim.api.nvim_win_get_buf(cur_win)
						if cur_buf ~= context.buf then
							local new_line_count = vim.api.nvim_buf_line_count(context.buf)
							vim.api.nvim_win_set_cursor(context.window, { new_line_count, 0 })
						end
					end
				end)
			end
		end

		-- TODO: commonise wth what's in ionide-vim

		-- Create a new buffer for build output
		local buf = vim.api.nvim_create_buf(false, true) -- No listed, scratch buffer

		-- Calculate window size and position here (example: full width, 10 lines high at the bottom)
		local width = vim.api.nvim_get_option_value("columns", {})
		local height = vim.api.nvim_get_option_value("lines", {})
		local win_height = math.min(10, math.floor(height * 0.2)) -- 20% of total height or 10 lines
		local original_win = vim.api.nvim_get_current_win()
		local win_opts = {
			relative = "editor",
			width = width,
			height = win_height,
			col = 0,
			row = height - win_height,
			style = "minimal",
			border = "single",
		}

		local win = vim.api.nvim_open_win(buf, true, win_opts)
		-- Switch back to the original window
		vim.api.nvim_set_current_win(original_win)

		local context = {
			window = win,
			buf = buf,
		}

		handle, _ = vim.uv.spawn(
			-- TODO: do we need to escape this? Don't know whether spawn goes via a shell
			venv_dir .. "/bin/python",
			{
				-- TODO: and do we need to escape this?
				args = { "-m", "pip", "install", "-r", requirements_path },
				stdio = { nil, stdout, stderr },
			},
			vim.schedule_wrap(function(code, signal)
				stdout:read_stop()
				stderr:read_stop()
				stdout:close()
				stderr:close()
				handle:close()
				print("Venv creation completed, exit code " .. code .. " and signal " .. signal)
				load_venv(venv_dir)
			end)
		)

		if not handle then
			print("Failed to start venv install process.")
			return
		end

		vim.uv.read_start(stdout, function(err, data)
			on_output(context, "OUT", err, data)
		end)
		vim.uv.read_start(stderr, function(err, data)
			on_output(context, "ERR", err, data)
		end)
	else
		load_venv(venv_dir)
	end
end

do
	local status, whichkey = pcall(require, "which-key")
	if status then
		whichkey.register({
			p = {
				name = "Python-related commands",
				v = {
					name = "Virtual environment-related commands",
					c = { CreateVenv, "Create virtual environment" },
					l = { SelectVenv, "Load virtual environment" },
					o = {
						function()
							vim.cmd("VenvSelect")
						end,
						"Choose (override) new virtual environment",
					},
				},
			},
		}, { prefix = vim.api.nvim_get_var("maplocalleader"), buffer = vim.api.nvim_get_current_buf() })
	else
		vim.api.nvim_set_keymap("n", "<localleader>pvc", ":lua CreateVenv()<CR>", { noremap = true })
		vim.api.nvim_set_keymap("n", "<localleader>pvl", ":lua SelectVenv()<CR>", { noremap = true })
		vim.api.nvim_set_keymap("n", "<localleader>pvo", ":VenvSelect<CR>", { noremap = true })
	end
end
