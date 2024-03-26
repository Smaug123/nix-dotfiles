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
	local function on_line(data, _, context)
		-- Keep the window alive if there were warnings
		if string.match(data, "%s[1-9]%d* Warning%(s%)") then
			context.warn = context.warn + 1
		end
	end

	local on_complete
	local function spawn_next(context)
		BuildUtils.run(
			"dotnet",
			{ "build", context.projects[context.completed + 1] },
			"dotnet build",
			context,
			on_line,
			on_complete
		)
	end

	on_complete = function(context, code, signal)
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

		if context.completed == context.expected then
			if context.errs == 0 and context.warn == 0 then
				-- Close the temporary floating window (but keep it alive if the
				-- cursor is in it)
				local cur_win = vim.api.nvim_get_current_win()
				local cur_buf = vim.api.nvim_win_get_buf(cur_win)
				if cur_buf ~= context.buf then
					vim.api.nvim_win_close(context.window, true)
				end
				print("All builds successful")
			end
		else
			spawn_next(context)
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
		local context = BuildUtils.create_window()
		context.warn = 0
		context.errs = 0
		context.completed = 0
		context.expected = total_projects
		context.projects = projects

		spawn_next(context)
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
