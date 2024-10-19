vim.g["fsharp#fsautocomplete_command"] = { "fsautocomplete" }
vim.g["fsharp#show_signature_on_cursor_move"] = 1
vim.g["fsharp#fsi_keymap"] = "none"

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
				if cur_buf ~= context.buffer then
					vim.api.nvim_win_close(context.window, true)
				end
				print("All builds successful")
			end
		else
			spawn_next(context)
		end
	end

	if not projects then
		projects = vim.fn["fsharp#getLoadedProjects"]()
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
				prompt_title = "Projects",
				finder = finders.new_table({
					results = vim.fn["fsharp#getLoadedProjects"](),
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

local function TableConcat(tables)
	local result = {}
	for _, tab in ipairs(tables) do
		for _, v in ipairs(tab) do
			table.insert(result, v)
		end
	end
	return result
end

-- args is a table that will be splatted into the command line and will be immediately
-- followed by the project.
local function RunDotnet(command, args, project, configuration)
	local function on_line(data, _, context) end

	local function on_complete(context, code, signal) end

	local context = BuildUtils.create_window()

	BuildUtils.run(
		"dotnet",
		TableConcat({ { command }, args, { project, "--configuration", configuration } }),
		"dotnet",
		context,
		on_line,
		on_complete
	)
end

-- Call this as:
-- RunFSharpProject path/to/fsproj
-- RunFSharpProject Debug path/to/fsproj
vim.api.nvim_create_user_command("RunFSharpProject", function(opts)
	local configuration = "Release"
	if opts.fargs and opts.fargs[1] and opts.fargs[1]:match("sproj$") then
		RunDotnet("run", { "--project" }, opts.fargs[1], configuration)
	elseif opts.fargs and opts.fargs[1] and opts.fargs[2] then
		configuration = opts.fargs[1]
		RunDotnet("run", { "--project" }, opts.fargs[2], configuration)
	else
		configuration = opts.fargs[1]
		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local action_state = require("telescope.actions.state")
		local actions = require("telescope.actions")
		pickers
			.new({}, {
				prompt_title = "Projects",
				finder = finders.new_table({
					results = vim.fn["fsharp#getLoadedProjects"](),
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_buf, _)
					actions.select_default:replace(function()
						actions.close(prompt_buf)
						local selection = action_state.get_selected_entry()
						RunDotnet("run", { "--project" }, selection.value, configuration)
					end)
					return true
				end,
			})
			:find()
	end
end, { nargs = "*", complete = "file" })

vim.api.nvim_create_user_command("PublishFSharpProject", function(opts)
	if opts.fargs and opts.fargs[1] then
		RunDotnet("publish", {}, opts.fargs[1], "Release")
	else
		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local action_state = require("telescope.actions.state")
		local actions = require("telescope.actions")
		pickers
			.new({}, {
				prompt_title = "Projects",
				finder = finders.new_table({
					results = vim.fn["fsharp#getLoadedProjects"](),
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_buf, _)
					actions.select_default:replace(function()
						actions.close(prompt_buf)
						local selection = action_state.get_selected_entry()
						RunDotnet("publish", {}, selection.value, "Release")
					end)
					return true
				end,
			})
			:find()
	end
end, { nargs = "*", complete = "file" })

vim.api.nvim_create_autocmd("FileType", {
	pattern = "fsharp",
	callback = function()
		local status, whichkey = pcall(require, "which-key")
		if status then
			whichkey.add({
				{ "<localleader>f", desc = "F#" },
				{ "<localleader>ft", ":call fsharp#showTooltip()<CR>", desc = "Show F# Tooltip" },
				{ "<localleader>fsi", ":call fsharp#toggleFsi()<CR>", desc = "Toggle FSI (F# Interactive)" },
				{ "<localleader>fsl", ":call fsharp#sendLineToFsi()<cr>", desc = "Send line to FSI (F# Interactive)" },
				{ "<localleader>fr", desc = "Run F# project" },
				{ "<localleader>frd", ":RunFSharpProject Debug", desc = "Run F# project in debug configuration" },
				{ "<localleader>frr", ":RunFSharpProject Release", desc = "Run F# project in release configuration" },
				{ "<localleader>fp", ":PublishFSharpProject", desc = "Publish F# project" },
				{ "<localleader>fb", desc = "Build F# project" },
				{ "<localleader>fba", BuildFSharpProjects, desc = "Build all projects" },
				{ "<localleader>fbs", ":BuildFSharpProject", desc = "Build specified project" },
			}, { buffer = vim.api.nvim_get_current_buf() })
		else
			vim.api.nvim_set_keymap("n", "<localleader>ft", ":call fsharp#showTooltip()<CR>", { noremap = true })
			vim.api.nvim_set_keymap("n", "<localleader>fsi", ":call fsharp#toggleFsi()<CR>", { noremap = true })
			vim.api.nvim_set_keymap("n", "<localleader>fsl", ":call fsharp#sendLineToFsi()<CR>", { noremap = true })
			vim.api.nvim_set_keymap("n", "<localleader>bpa", ":lua BuildFSharpProjects()", { noremap = true })
			vim.api.nvim_set_keymap("n", "<localleader>bps", ":BuildFSharpProject", { noremap = true })
		end
	end,
})
