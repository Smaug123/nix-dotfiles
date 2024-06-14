BuildUtils = {}

-- Create a new buffer and a new floating window to hold that buffer.
local function create_floating_window()
	-- Create a new buffer for build output
	local buf = vim.api.nvim_create_buf(false, true) -- No listed, scratch buffer

	-- Calculate window size and position here (example: full width, 10 lines high at the bottom)
	local width = vim.api.nvim_get_option_value("columns", {})
	local height = vim.api.nvim_get_option_value("lines", {})
	local win_height = math.min(10, math.floor(height * 0.2)) -- 20% of total height or 10 lines
	local win_opts = {
		relative = "editor",
		width = width,
		height = win_height,
		col = 0,
		row = height - win_height,
		style = "minimal",
		border = "single",
	}

	local win = vim.api.nvim_open_win(buf, false, win_opts)

	return { window = win, buffer = buf }
end

local function _on_output(context, is_stdout, err, data, on_line)
	local prefix
	if is_stdout then
		prefix = "OUT"
	else
		prefix = "ERR"
	end
	if err or data then
		vim.schedule(function()
			if err then
				-- Append the error message to the buffer
				local count = vim.api.nvim_buf_line_count(context.buffer)
				vim.api.nvim_buf_set_lines(context.buffer, count, count, false, { "error " .. prefix .. ": " .. err })
			end
			if data then
				-- Append the data to the buffer
				local count = vim.api.nvim_buf_line_count(context.buffer)
				vim.api.nvim_buf_set_lines(
					context.buffer,
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
				if cur_buf ~= context.buffer then
					local new_line_count = vim.api.nvim_buf_line_count(context.buffer)
					vim.api.nvim_win_set_cursor(context.window, { new_line_count, 0 })
				end
			end

			on_line(data, is_stdout, context)
		end)
	end
end

-- Arguments:
-- * exe, a string (no need to escape this)
-- * args, a table like { "-m", "venv", vim.fn.shellescape(some_path) }
-- * description of this process, visible to the user, e.g. "venv creation"
-- * context, the result of `create_floating_window`
-- * on_line, a function which takes "the string written", (true if stdout else false), and the context table; should return nothing. We'll call that on every line of stdout and stderr.
-- * on_complete, takes `context`, `code` (exit code) and `signal` ("documented" with neovim's uv.spawn, hah)
local function run_external(exe, args, description, context, on_line, on_complete)
	local handle
	local stdout = vim.uv.new_pipe(false)
	local stderr = vim.uv.new_pipe(false)
	handle, _ = vim.uv.spawn(
		exe,
		{
			args = args,
			stdio = { nil, stdout, stderr },
		},
		vim.schedule_wrap(function(code, signal)
			stdout:read_stop()
			stderr:read_stop()
			stdout:close()
			stderr:close()
			handle:close()
			print("External process " .. description .. " completed, exit code " .. code .. " and signal " .. signal)
			on_complete(context, code, signal)
		end)
	)

	if not handle then
		print("Failed to start " .. description .. " process.")
		return
	end

	vim.uv.read_start(stdout, function(err, data)
		_on_output(context, true, err, data, on_line)
	end)
	vim.uv.read_start(stderr, function(err, data)
		_on_output(context, false, err, data, on_line)
	end)
end

BuildUtils.create_window = create_floating_window
BuildUtils.run = run_external
