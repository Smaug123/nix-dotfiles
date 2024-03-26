vim.g["fsharp#fsautocomplete_command"] = { "fsautocomplete" }
vim.g["fsharp#show_signature_on_cursor_move"] = 1
vim.g["fsharp#fsi_keymap"] = "none"

-- MASSIVE HACK - raised https://github.com/ionide/Ionide-vim/pull/78
local function captureLoadedProjects()
	vim.fn.execute("redir => g:massive_hack_patrick_capture")
	vim.fn.execute("call fsharp#showLoadedProjects()")
	vim.fn.execute("redir END")
	local output = vim.fn.eval("g:massive_hack_patrick_capture")

	local projects = {}

	for line in output:gmatch("[^\r\n]+") do
		local project = line:gsub("^%s*-%s*", "")
		table.insert(projects, project)
	end

	return projects
end

-- Supply nil to get all loaded F# projects and build them.
local function BuildFSharpProjects(projects)
	local function on_output(context, prefix, err, data)
		if err or data then
			vim.schedule(function()
				if err then
					-- Append the error message to the buffer
					local count = vim.api.nvim_buf_line_count(context.buf)
					vim.api.nvim_buf_set_lines(context.buf, count, count, false, { "error " .. prefix .. ": " .. err })
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
				-- Keep the window alive if there were warnings
				if string.match(data, "%s[1-9]%d* Warning%(s%)") then
					context.warn = context.warn + 1
				end
			end)
		end
	end

	local function spawn_next(context)
		if context.completed == context.expected then
			if context.errs == 0 and context.warn == 0 then
				local cur_win = vim.api.nvim_get_current_win()
				local cur_buf = vim.api.nvim_win_get_buf(cur_win)
				if cur_buf ~= context.buf then
					vim.api.nvim_win_close(context.window, true)
				end
				print("All builds successful")
			end
		else
			local handle
			local stdout = vim.uv.new_pipe(false)
			local stderr = vim.uv.new_pipe(false)

			handle, _ = vim.uv.spawn(
				"dotnet",
				{
					args = { "build", context.projects[context.completed + 1] },
					stdio = { nil, stdout, stderr },
				},
				vim.schedule_wrap(function(code, signal)
					stdout:read_stop()
					stderr:read_stop()
					stdout:close()
					stderr:close()
					handle:close()
					print("Build process exited with code " .. code .. " and signal " .. signal)
					if code ~= 0 then
						context.errs = context.errs + 1
					end
					context.completed = context.completed + 1

					print(
						"Completed: "
							.. context.completed
							.. " out of "
							.. context.expected
							.. " (errors: "
							.. context.errs
							.. ", warnings: "
							.. context.warn
							.. ")"
					)

					spawn_next(context)
				end)
			)

			if not handle then
				print("Failed to start build process.")
				return
			end

			vim.uv.read_start(stdout, function(err, data)
				on_output(context, "OUT", err, data)
			end)
			vim.uv.read_start(stderr, function(err, data)
				on_output(context, "ERR", err, data)
			end)
		end
	end

	if not projects then
		projects = captureLoadedProjects()
	end
	if projects then
		local total_projects = 0
		for _, _ in ipairs(projects) do
			total_projects = total_projects + 1
		end

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

		local build_context = {
			warn = 0,
			errs = 0,
			completed = 0,
			expected = total_projects,
			window = win,
			projects = projects,
			buf = buf,
		}

		spawn_next(build_context)
	end
end

-- local function fsprojAndDirCompletion(ArgLead, _, _)
-- 	local results = {}
-- 	local loc = ArgLead
-- 	if not loc then
-- 		loc = "."
-- 	end
-- 	local command = string.format(
-- 		"find "
-- 			.. vim.fn.shellescape(loc)
-- 			.. " -maxdepth 2 \\( -type f -name '*.fsproj' -o -type d \\) -print0 2> /dev/null"
-- 	)
-- 	local handle = io.popen(command)
-- 	if handle then
-- 		local stdout = handle:read("*all")
-- 		handle:close()
--
-- 		local allResults = {}
-- 		for match in string.gmatch(stdout, "([^%z]+)") do
-- 			table.insert(allResults, match)
-- 		end
-- 		table.sort(allResults, function(a, b)
-- 			local aEndsWithProj = a:match("proj$")
-- 			local bEndsWithProj = b:match("proj$")
-- 			if aEndsWithProj and not bEndsWithProj then
-- 				return true
-- 			elseif not aEndsWithProj and bEndsWithProj then
-- 				return false
-- 			else
-- 				return a < b -- If both or neither end with 'proj', sort alphabetically
-- 			end
-- 		end)
--
-- 		for _, line in ipairs(allResults) do
-- 			table.insert(results, line)
-- 		end
-- 	end
-- 	return results
-- end

vim.api.nvim_create_user_command("BuildFSharpProject", function(opts)
	if opts.fargs and opts.fargs[1] then
		BuildFSharpProjects(opts.fargs)
	else
		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local action_state = require("telescope.actions.state")
		local actions = require("telescope.actions")
		pickers
			.new({}, {
				prompt_title = "Actions",
				finder = finders.new_table({
					results = captureLoadedProjects(),
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_buf, _)
					actions.select_default:replace(function()
						actions.close(prompt_buf)
						local selection = action_state.get_selected_entry()
						BuildFSharpProjects({ selection.value })
					end)
					return true
				end,
			})
			:find()
	end
end, { nargs = "?", complete = "file" })

vim.api.nvim_create_autocmd("FileType", {
	pattern = "fsharp",
	callback = function()
		local status, whichkey = pcall(require, "which-key")
		if status then
			whichkey.register({
				f = {
					t = { ":call fsharp#showTooltip()<CR>", "Show F# Tooltip" },
					["si"] = { ":call fsharp#toggleFsi()<CR>", "Toggle FSI (F# Interactive)" },
					["sl"] = { ":call fsharp#sendLineToFsi()<cr>", "Send line to FSI (F# Interactive)" },
				},
				b = {
					p = {
						a = { BuildFSharpProjects, "Build all projects" },
						s = { ":BuildFSharpProject", "Build specified project" },
					},
				},
			}, { prefix = vim.api.nvim_get_var("maplocalleader"), buffer = vim.api.nvim_get_current_buf() })
		else
			vim.api.nvim_set_keymap("n", "<localleader>ft", ":call fsharp#showTooltip()<CR>", { noremap = true })
			vim.api.nvim_set_keymap("n", "<localleader>fsi", ":call fsharp#toggleFsi()<CR>", { noremap = true })
			vim.api.nvim_set_keymap("n", "<localleader>fsl", ":call fsharp#sendLineToFsi()<CR>", { noremap = true })
			vim.api.nvim_set_keymap("n", "<localleader>bpa", BuildFSharpProjects, { noremap = true })
			vim.api.nvim_set_keymap("n", "<localleader>bps", ":BuildFSharpProject", { noremap = true })
		end
	end,
})
