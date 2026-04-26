local dotnet_has_set_status_line

function DetachSolution()
	vim.g.current_sln_path = nil
	-- TODO: unregister key bindings again
end

local function on_line(data, _, context)
	-- Keep the window alive if there were warnings
	if string.match(data, "%s[1-9]%d* Warning%(s%)") then
		context.warn = context.warn + 1
	end
end
local function on_complete(context, code, _)
	if code ~= 0 then
		print("Exit code " .. code)
		context.errs = context.errs + 1
	end

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
end

function GetCurrentSln()
	if vim.g.current_sln_path then
		return vim.g.current_sln_path
	else
		return nil
	end
end

function BuildDotNetSolution()
	if vim.g.current_sln_path then
		local context = BuildUtils.create_window()
		context.errs = 0
		context.warn = 0
		BuildUtils.run("dotnet", { "build", vim.g.current_sln_path }, "dotnet build", context, on_line, on_complete)
	end
end

function TestDotNetSolution()
	if vim.g.current_sln_path then
		local context = BuildUtils.create_window()
		context.warn = 0
		context.errs = 0
		BuildUtils.run("dotnet", { "test", vim.g.current_sln_path }, "dotnet test", context, on_line, on_complete)
	end
end

-- Parse a .sln file (classic format) and extract project paths
---@param sln_path string
---@param sln_dir string
---@return string[]
local function get_projects_from_sln(sln_path, sln_dir)
	local projects = {}
	local file = io.open(sln_path, "r")
	if not file then
		return projects
	end

	for line in file:lines() do
		-- Match: Project("{GUID}") = "Name", "path/to/project.csproj", "{GUID}"
		-- Also matches .fsproj (the [cf] character class matches both c and f)
		local proj_path = line:match('Project%("[^"]+"%)[^"]*"[^"]+"%s*,%s*"([^"]+%.[cf]sproj)"')
		if proj_path then
			-- Normalize path separators (Windows -> Unix)
			proj_path = proj_path:gsub("\\", "/")
			local full_path = sln_dir .. "/" .. proj_path
			-- Normalize the path
			full_path = vim.fn.fnamemodify(full_path, ":p")
			if vim.fn.filereadable(full_path) == 1 then
				table.insert(projects, full_path)
			end
		end
	end
	file:close()
	return projects
end

-- Parse a .slnx file (XML format) and extract project paths
---@param sln_path string
---@param sln_dir string
---@return string[]
local function get_projects_from_slnx(sln_path, sln_dir)
	local projects = {}
	local file = io.open(sln_path, "r")
	if not file then
		return projects
	end

	for line in file:lines() do
		-- Match: <Project Path="path/to/project.fsproj" /> or <Project Path="path/to/project.csproj" />
		local proj_path = line:match('<Project[^>]+Path="([^"]+%.[cf]sproj)"')
		if proj_path then
			-- Normalize path separators (Windows -> Unix)
			proj_path = proj_path:gsub("\\", "/")
			local full_path = sln_dir .. "/" .. proj_path
			-- Normalize the path
			full_path = vim.fn.fnamemodify(full_path, ":p")
			if vim.fn.filereadable(full_path) == 1 then
				table.insert(projects, full_path)
			end
		end
	end
	file:close()
	return projects
end

-- Parse a solution file (.sln or .slnx) and extract project paths
---@param sln_path string
---@return string[]
local function get_projects_from_solution(sln_path)
	local sln_dir = vim.fn.fnamemodify(sln_path, ":h")
	local ext = vim.fn.fnamemodify(sln_path, ":e")

	if ext == "slnx" then
		return get_projects_from_slnx(sln_path, sln_dir)
	else
		return get_projects_from_sln(sln_path, sln_dir)
	end
end

-- Read project file content (cached for the session)
---@type table<string, string>
local _project_content_cache = {}

---@param proj_path string
---@return string|nil
local function get_project_content(proj_path)
	if _project_content_cache[proj_path] then
		return _project_content_cache[proj_path]
	end
	local file = io.open(proj_path, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	_project_content_cache[proj_path] = content
	return content
end

-- Check if a project is a test project (has Microsoft.NET.Test.Sdk)
---@param proj_path string
---@return boolean
local function is_test_project(proj_path)
	local content = get_project_content(proj_path)
	if not content then
		return false
	end
	return content:match('PackageReference[^>]+Include="Microsoft%.NET%.Test%.Sdk"') ~= nil
end

-- Check if a project is executable (has <OutputType>Exe</OutputType> or is a web project)
---@param proj_path string
---@return boolean
local function is_executable_project(proj_path)
	local content = get_project_content(proj_path)
	if not content then
		return false
	end

	-- Check for explicit Exe output type
	if content:match("<OutputType>Exe</OutputType>") then
		return true
	end

	-- Web SDK projects are implicitly executable
	if content:match('Sdk="Microsoft%.NET%.Sdk%.Web"') then
		return true
	end

	return false
end

-- Get the output DLL path for a project
---@param proj_path string
---@param configuration string
---@return string
local function get_project_output_path(proj_path, configuration)
	local proj_dir = vim.fn.fnamemodify(proj_path, ":h")
	local proj_name = vim.fn.fnamemodify(proj_path, ":t:r")

	-- Try to find the actual output by checking bin directory
	local bin_dir = proj_dir .. "/bin/" .. configuration
	local pattern = bin_dir .. "/net*/" .. proj_name .. ".dll"
	local matches = vim.fn.glob(pattern, nil, true)

	if #matches > 0 then
		-- Return the most recently modified one
		table.sort(matches, function(a, b)
			return vim.fn.getftime(a) > vim.fn.getftime(b)
		end)
		return matches[1]
	end

	-- Fallback: construct a likely path
	return bin_dir .. "/net8.0/" .. proj_name .. ".dll"
end

-- Get all executable projects from the current solution
---@return {path: string, name: string, dll: string, is_test: boolean}[]
local function get_debuggable_projects()
	local sln = GetCurrentSln()
	if not sln then
		return {}
	end

	local projects = get_projects_from_solution(sln)
	local debuggables = {}

	for _, proj_path in ipairs(projects) do
		if is_executable_project(proj_path) then
			local name = vim.fn.fnamemodify(proj_path, ":t:r")
			table.insert(debuggables, {
				path = proj_path,
				name = name,
				dll = get_project_output_path(proj_path, "Debug"),
				is_test = is_test_project(proj_path),
			})
		end
	end

	return debuggables
end

-- Debug a specific project
---@param project {path: string, name: string, dll: string, is_test: boolean}
---@param build_first boolean
local function debug_project(project, build_first)
	local dap = require("dap")

	-- Test projects should use test debugging
	if project.is_test then
		print("This is a test project. Use ;sdt to debug a specific test, or ;sda for all tests.")
		return
	end

	local function start_debug()
		-- Check if DLL exists
		if vim.fn.filereadable(project.dll) ~= 1 then
			print("DLL not found: " .. project.dll .. " - try building first")
			return
		end

		dap.run({
			type = "coreclr",
			name = "Debug " .. project.name,
			request = "launch",
			program = project.dll,
			cwd = vim.fn.fnamemodify(project.path, ":h"),
		})
	end

	if build_first then
		local context = BuildUtils.create_window()
		context.errs = 0
		context.warn = 0
		BuildUtils.run("dotnet", { "build", project.path }, "dotnet build " .. project.name, context, on_line, function(ctx, code, _)
			on_complete(ctx, code, nil)
			if code == 0 then
				-- Refresh the DLL path after build
				project.dll = get_project_output_path(project.path, "Debug")
				vim.schedule(start_debug)
			end
		end)
	else
		start_debug()
	end
end

-- Pick a project to debug using Telescope
---@param build_first boolean
local function pick_and_debug_project(build_first)
	local debuggables = get_debuggable_projects()

	if #debuggables == 0 then
		print("No executable projects found in solution")
		return
	end

	if #debuggables == 1 then
		debug_project(debuggables[1], build_first)
		return
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local conf = require("telescope.config").values

	pickers
		.new({}, {
			prompt_title = "Select project to debug",
			finder = finders.new_table({
				results = debuggables,
				entry_maker = function(entry)
					local display = entry.name
					if entry.is_test then
						display = display .. " [test - use ;sdt]"
					end
					return {
						value = entry,
						display = display,
						ordinal = entry.name,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					debug_project(selection.value, build_first)
				end)
				return true
			end,
		})
		:find()
end

function DebugDotNetProject()
	pick_and_debug_project(false)
end

function BuildAndDebugDotNetProject()
	pick_and_debug_project(true)
end

-- Find the project that contains the current file
---@return string|nil
local function find_project_for_current_file()
	local current_file = vim.fn.expand("%:p")
	local sln = GetCurrentSln()
	if not sln then
		return nil
	end

	local projects = get_projects_from_solution(sln)
	for _, proj_path in ipairs(projects) do
		local proj_dir = vim.fn.fnamemodify(proj_path, ":h")
		if current_file:sub(1, #proj_dir) == proj_dir then
			return proj_path
		end
	end
	return nil
end

-- Find the test name at the cursor position (NUnit)
-- Returns: fully qualified test name or nil
---@return string|nil, string|nil  -- test_filter, display_name
local function find_test_at_cursor()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local cursor_line = cursor[1]

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	-- Find the namespace and module/type containing the cursor
	local namespace = nil
	local current_type = nil
	local current_test = nil

	-- Track nesting for F# modules
	local module_stack = {}

	for i, line in ipairs(lines) do
		-- F# namespace
		local ns = line:match("^namespace%s+([%w%.]+)")
		if ns then
			namespace = ns
		end

		-- F# module (can be nested)
		local mod = line:match("^module%s+([%w_]+)%s*=?") or line:match("^%s*module%s+([%w_]+)%s*=")
		if mod then
			-- Simple heuristic: top-level module vs nested
			if line:match("^module%s") then
				module_stack = { mod }
			else
				table.insert(module_stack, mod)
			end
			current_type = table.concat(module_stack, "+")
		end

		-- F# type (class)
		local typ = line:match("^type%s+([%w_]+)") or line:match("^%s+type%s+([%w_]+)")
		if typ and not line:match("^type%s+%w+%s*=") then -- Exclude type aliases
			current_type = typ
		end

		-- Check for test attributes on this line or the previous line
		if i == cursor_line or i == cursor_line - 1 then
			if line:match("%[<Test") or line:match("%[<TestCase") or line:match("%[<Property") then
				-- The test is on the next line (or this line if it's a let binding)
				local test_line = (i == cursor_line) and line or lines[cursor_line]
				local test_name = test_line:match("let%s+([%w_'`]+)") or test_line:match("member%s+[%w_]+%.([%w_]+)")
				if test_name then
					-- Remove backticks from F# names like ``test name``
					test_name = test_name:gsub("``", "")
					current_test = test_name
					break
				end
			end
		end

		-- Also check if cursor is on a let binding that might be a test
		if i == cursor_line then
			local test_name = line:match("let%s+([%w_'`]+)") or line:match("member%s+[%w_]+%.([%w_]+)")
			if test_name then
				-- Check if previous lines have test attributes
				for j = math.max(1, i - 3), i - 1 do
					if lines[j]:match("%[<Test") or lines[j]:match("%[<TestCase") or lines[j]:match("%[<Property") then
						test_name = test_name:gsub("``", "")
						current_test = test_name
						break
					end
				end
			end
		end
	end

	if current_test then
		local full_name = ""
		if namespace then
			full_name = namespace .. "."
		end
		if current_type then
			full_name = full_name .. current_type .. "."
		end
		full_name = full_name .. current_test

		-- NUnit filter syntax
		return "FullyQualifiedName~" .. current_test, full_name
	end

	return nil, nil
end

-- Find the test fixture (class/module) at cursor
---@return string|nil, string|nil  -- test_filter, display_name
local function find_test_fixture_at_cursor()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local namespace = nil
	local current_type = nil

	for _, line in ipairs(lines) do
		local ns = line:match("^namespace%s+([%w%.]+)")
		if ns then
			namespace = ns
		end

		local mod = line:match("^module%s+([%w_]+)")
		if mod then
			current_type = mod
		end

		local typ = line:match("^type%s+([%w_]+)")
		if typ then
			current_type = typ
		end
	end

	if current_type then
		local full_name = namespace and (namespace .. "." .. current_type) or current_type
		return "FullyQualifiedName~" .. current_type, full_name
	end

	return nil, nil
end

-- Debug a test using dotnet test with VSTEST_HOST_DEBUG
-- This launches dotnet test which pauses waiting for debugger, then we attach
---@param project_path string
---@param filter string|nil
---@param display_name string
---@param build_first boolean
local function debug_test(project_path, filter, display_name, build_first)
	local dap = require("dap")
	local proj_dir = vim.fn.fnamemodify(project_path, ":h")

	local function start_debug()
		local args = { "test", "--no-build", project_path }
		if filter then
			table.insert(args, "--filter")
			table.insert(args, filter)
		end

		print("Starting test with debugger: " .. display_name)
		print("Waiting for testhost to start...")

		-- Launch dotnet test with VSTEST_HOST_DEBUG=1 in background
		-- It will print "Process Id: XXXX" and wait for debugger
		local stdout = vim.uv.new_pipe(false)
		local stderr = vim.uv.new_pipe(false)
		local output = ""
		local attached = false

		local handle
		handle = vim.uv.spawn("dotnet", {
			args = args,
			cwd = proj_dir,
			stdio = { nil, stdout, stderr },
			env = vim.tbl_extend("force", vim.fn.environ(), { VSTEST_HOST_DEBUG = "1" }),
		}, function(code, _)
			stdout:close()
			stderr:close()
			if handle then
				handle:close()
			end
			if code ~= 0 and not attached then
				vim.schedule(function()
					print("dotnet test exited with code " .. code)
				end)
			end
		end)

		local function process_output(data)
			if not data then
				return
			end
			output = output .. data

			-- Look for "Process Id: XXXX, Name: testhost"
			local pid = output:match("Process Id:%s*(%d+)")
			if pid and not attached then
				attached = true
				vim.schedule(function()
					print("Attaching to testhost (PID: " .. pid .. ")")
					dap.run({
						type = "coreclr",
						name = "Attach to testhost",
						request = "attach",
						processId = tonumber(pid),
					})
				end)
			end
		end

		vim.uv.read_start(stdout, function(err, data)
			assert(not err, err)
			process_output(data)
		end)
		vim.uv.read_start(stderr, function(err, data)
			assert(not err, err)
			process_output(data)
		end)
	end

	if build_first then
		local context = BuildUtils.create_window()
		context.errs = 0
		context.warn = 0
		BuildUtils.run("dotnet", { "build", project_path }, "dotnet build", context, on_line, function(ctx, code, _)
			on_complete(ctx, code, nil)
			if code == 0 then
				vim.schedule(start_debug)
			end
		end)
	else
		start_debug()
	end
end

-- Debug the test at cursor
---@param build_first boolean
local function debug_test_at_cursor(build_first)
	local proj_path = find_project_for_current_file()
	if not proj_path then
		print("Could not find project for current file")
		return
	end

	if not is_test_project(proj_path) then
		print("Current file is not in a test project")
		return
	end

	local filter, display_name = find_test_at_cursor()
	if not filter then
		print("No test found at cursor")
		return
	end

	debug_test(proj_path, filter, display_name, build_first)
end

-- Debug all tests in the current fixture/module
---@param build_first boolean
local function debug_test_fixture(build_first)
	local proj_path = find_project_for_current_file()
	if not proj_path then
		print("Could not find project for current file")
		return
	end

	if not is_test_project(proj_path) then
		print("Current file is not in a test project")
		return
	end

	local filter, display_name = find_test_fixture_at_cursor()
	if not filter then
		print("No test fixture found")
		return
	end

	debug_test(proj_path, filter, display_name, build_first)
end

-- Debug all tests in the current project
---@param build_first boolean
local function debug_all_tests_in_project(build_first)
	local proj_path = find_project_for_current_file()
	if not proj_path then
		print("Could not find project for current file")
		return
	end

	if not is_test_project(proj_path) then
		print("Current file is not in a test project")
		return
	end

	local proj_name = vim.fn.fnamemodify(proj_path, ":t:r")
	debug_test(proj_path, nil, proj_name, build_first)
end

function DebugTestAtCursor()
	debug_test_at_cursor(true)
end

function DebugTestFixture()
	debug_test_fixture(true)
end

function DebugAllTestsInProject()
	debug_all_tests_in_project(true)
end

function CurrentSlnOrEmpty()
	local sln = GetCurrentSln()
	if sln then
		return sln
	else
		return ""
	end
end

function RegisterSolution(sln_path)
	vim.g.current_sln_path = sln_path

	if not dotnet_has_set_status_line then
		dotnet_has_set_status_line = true
		vim.o.statusline = vim.o.statusline .. "  %{v:lua.CurrentSlnOrEmpty()}"
	end

	local whichkey = require("which-key")
	whichkey.add({
		{
			"<localleader>s",
			desc = ".NET solution",
		},
		{ "<localleader>sb", BuildDotNetSolution, desc = "Build .NET solution" },
		{ "<localleader>st", TestDotNetSolution, desc = "Test .NET solution" },
		{ "<localleader>sd", desc = "Debug" },
		{ "<localleader>sdp", DebugDotNetProject, desc = "Debug .NET project" },
		{ "<localleader>sdP", BuildAndDebugDotNetProject, desc = "Build and debug .NET project" },
		{ "<localleader>sdt", DebugTestAtCursor, desc = "Debug test at cursor" },
		{ "<localleader>sdf", DebugTestFixture, desc = "Debug test fixture/module" },
		{ "<localleader>sda", DebugAllTestsInProject, desc = "Debug all tests in project" },
	}, { buffer = vim.api.nvim_get_current_buf() })
end

local function find_nearest_slns()
	local path = vim.fn.expand("%:p:h") -- Get the full path of the current buffer's directory

	while path and path ~= "/" do
		-- Look for both .sln and .slnx files
		local sln_paths = vim.fn.glob(path .. "/*.sln", nil, true)
		local slnx_paths = vim.fn.glob(path .. "/*.slnx", nil, true)
		vim.list_extend(sln_paths, slnx_paths)
		if #sln_paths > 0 then
			return sln_paths
		end
		path = vim.fn.fnamemodify(path, ":h") -- Move up one directory
	end

	return {}
end

local function FindAndRegisterSolution(should_override)
	if not should_override and GetCurrentSln() ~= nil then
		RegisterSolution(GetCurrentSln())
	end

	local solutions = find_nearest_slns()
	if not solutions or #solutions == 0 then
		print("No .sln or .slnx file found in any parent directory.")
		return
	elseif #solutions == 1 then
		-- Exactly one solution found; register it directly
		RegisterSolution(solutions[1])
	elseif #solutions > 1 then
		-- Multiple solutions found; use Telescope to pick one
		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")
		local conf = require("telescope.config").values

		pickers
			.new({}, {
				prompt_title = "Select a Solution File",
				finder = finders.new_table({
					results = solutions,
					entry_maker = function(entry)
						return {
							value = entry,
							display = entry,
							ordinal = entry,
						}
					end,
				}),
				sorter = conf.generic_sorter({}),
				attach_mappings = function(prompt_bufnr, _)
					actions.select_default:replace(function()
						local selection = action_state.get_selected_entry()
						actions.close(prompt_bufnr)
						RegisterSolution(selection.value)
					end)
					return true
				end,
			})
			:find()
	end
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
	pattern = { "*.sln", "*.slnx" },
	callback = function()
		if GetCurrentSln() == nil then
			RegisterSolution(vim.fn.expand("%:p"))
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "fsharp", "cs", "fsharp_project" },
	callback = function()
		FindAndRegisterSolution(false)
	end,
})

-- For what I'm sure are reasons, Lua appears to have nothing in its standard library
---@generic K
---@generic V1
---@generic V2
---@param tbl table<K, V1>
---@param f fun(V1): V2
---@return table<K, V2>
local function map(tbl, f)
	local t = {}
	for k, v in pairs(tbl) do
		t[k] = f(v)
	end
	return t
end

---@generic K
---@generic V
---@param tbl table<K, V>
---@param f fun(V1): nil
local function iter(tbl, f)
	for _, v in pairs(tbl) do
		f(v)
	end
end

---@generic K
---@generic V
---@param tbl table<K, V>
---@param predicate fun(V): boolean
---@return boolean, V
local function find(tbl, predicate)
	for _, v in pairs(tbl) do
		if predicate(v) then
			return true, v
		end
	end
	return false, nil
end

---@class (exact) NuGetVersion
---@field major number
---@field minor number
---@field patch number
---@field suffix? string
local NuGetVersion = {}

---@param v NuGetVersion
---@nodiscard
---@return string
local function nuGetVersionToString(v)
	local s = tostring(v.major) .. "." .. tostring(v.minor) .. "." .. tostring(v.patch)
	if v.suffix then
		return s .. v.suffix
	else
		return s
	end
end

local function get_all_variables()
	local variables = {}
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	for _, line in ipairs(lines) do
		local var_name, var_value = line:match("<(%w+)>([^<]+)</(%w+)>")
		if var_name and var_value then
			variables[var_name] = var_value
		end
	end
	return variables
end

local function resolve_variable(version, variables)
	if version:match("^%$%((.+)%)$") then
		local var_name = version:match("^%$%((.+)%)$")
		return variables[var_name] or nil
	end
	return nil
end

---@param v string
---@nodiscard
---@return NuGetVersion
local function parse_version(v)
	local variables = get_all_variables()
	local major, minor, patch, pre = v:match("(%d+)%.(%d+)%.(%d+)(.*)$")
	if major == nil then
		local resolved = resolve_variable(v, variables)
		if resolved ~= nil then
			return parse_version(resolved)
		end
	end
	-- TODO: why does this type-check if you remove the field names?
	return {
		major = tonumber(major) or 0,
		minor = tonumber(minor) or 0,
		patch = tonumber(patch) or 0,
		suffix = pre or nil,
	}
end

---@param a NuGetVersion
---@param b NuGetVersion
---@nodiscard
---@return boolean
local function compare_versions(a, b)
	if a.major ~= b.major then
		return a.major < b.major
	elseif a.minor ~= b.minor then
		return a.minor < b.minor
	elseif a.patch ~= b.patch then
		return a.patch < b.patch
	elseif a.suffix and not b.suffix then
		return false
	elseif not a.suffix and b.suffix then
		return true
	else
		return a.suffix < b.suffix
	end
end

---@param url string
---@nodiscard
local function curl_sync(url)
	local command = string.format("_CURL_ --silent --compressed --fail '%s'", url)
	local response = vim.fn.system(command)
	if vim.v.shell_error ~= 0 then
		print("Failed to fetch " .. url)
		return nil
	end
	local success, decoded = pcall(vim.fn.json_decode, response)
	if not success then
		print("Failed to decode JSON from curl at " .. url)
		return nil
	end
	return decoded
end

---@param url string
---@param callback fun(table): nil
---@return nil
local function curl(url, callback)
	local stdout = vim.uv.new_pipe(false)
	local stdout_text = ""
	local handle
	handle, _ = vim.uv.spawn(
		"_CURL_",
		{ args = { "--silent", "--compressed", "--fail", url }, stdio = { nil, stdout, nil } },
		vim.schedule_wrap(function(code, _)
			stdout:read_stop()
			stdout:close()
			if handle and not handle:is_closing() then
				handle:close()
			end
			if code ~= 0 then
				print("Failed to fetch " .. url)
			end
			local success, decoded = pcall(vim.fn.json_decode, stdout_text)
			if not success then
				print("Failed to decode JSON from curl at " .. url .. "\n" .. stdout_text)
			end
			callback(decoded)
		end)
	)
	vim.uv.read_start(stdout, function(err, data)
		assert(not err, err)
		if data then
			stdout_text = stdout_text .. data
		end
	end)
end

local _nugetIndex
local _packageBaseAddress

---@param callback fun(): nil
local function populate_nuget_api(callback)
	if _nugetIndex ~= nil then
		callback()
	end
	local url = string.format("https://api.nuget.org/v3/index.json")
	local function handle(decoded)
		local default_nuget_reg = "https://api.nuget.org/v3/registration5-semver1/"
		local default_base_address = "https://api.nuget.org/v3-flatcontainer/"

		if not decoded then
			print("Failed to fetch NuGet index; falling back to default")
			_nugetIndex = default_nuget_reg
			_packageBaseAddress = default_base_address
		else
			local resources = decoded["resources"]
			if resources == nil then
				print("Failed to parse: " .. decoded .. tostring(decoded))
				for k, v in pairs(decoded) do
					print(k .. ": " .. tostring(v))
				end
				callback()
				return
			end

			local resourceSuccess, regUrl = find(resources, function(o)
				return o["@type"] == "RegistrationsBaseUrl/3.6.0"
			end)
			if not resourceSuccess then
				print("Failed to find endpoint in NuGet index; falling back to default")
				_nugetIndex = default_nuget_reg
			else
				_nugetIndex = regUrl["@id"]
			end

			local baseAddrSuccess, baseAddrUrl = find(resources, function(o)
				return o["@type"] == "PackageBaseAddress/3.0.0"
			end)
			if not baseAddrSuccess then
				print("Failed to find endpoint in NuGet index; falling back to default")
				_packageBaseAddress = default_base_address
			else
				_packageBaseAddress = baseAddrUrl["@id"]
			end
		end
		callback()
	end
	curl(url, handle)
end

---@return nil
local function populate_nuget_api_sync()
	if _nugetIndex ~= nil then
		return
	end
	local url = string.format("https://api.nuget.org/v3/index.json")
	local decoded = curl_sync(url)
	local default_nuget_reg = "https://api.nuget.org/v3/registration5-semver1/"
	local default_base_address = "https://api.nuget.org/v3-flatcontainer/"

	if not decoded then
		print("Failed to fetch NuGet index; falling back to default")
		_nugetIndex = default_nuget_reg
		_packageBaseAddress = default_base_address
	else
		local resources = decoded["resources"]

		local resourceSuccess, regUrl = find(resources, function(o)
			return o["@type"] == "RegistrationsBaseUrl/3.6.0"
		end)
		if not resourceSuccess then
			print("Failed to find endpoint in NuGet index; falling back to default")
			_nugetIndex = default_nuget_reg
		else
			_nugetIndex = regUrl["@id"]
		end

		local baseAddrSuccess, baseAddrUrl = find(resources, function(o)
			return o["@type"] == "PackageBaseAddress/3.0.0"
		end)
		if not baseAddrSuccess then
			print("Failed to find endpoint in NuGet index; falling back to default")
			_packageBaseAddress = default_base_address
		else
			_packageBaseAddress = baseAddrUrl["@id"]
		end
	end
end

---@return nil
---@param callback fun(nugetIndex: string): nil
local function get_nuget_index(callback)
	populate_nuget_api(function()
		callback(_nugetIndex)
	end)
end

---@return nil
---@param callback fun(packageBaseIndex: string): nil
local function get_package_base_addr(callback)
	populate_nuget_api(function()
		callback(_packageBaseAddress)
	end)
end

---@return string
local function get_package_base_addr_sync()
	populate_nuget_api_sync()
	return _packageBaseAddress
end

local _package_versions_cache = {}

---@param package_name string
---@return NuGetVersion[]
local function get_package_versions_sync(package_name)
	if _package_versions_cache[package_name] ~= nil then
		return _package_versions_cache[package_name]
	end
	local base = get_package_base_addr_sync()

	local url = base .. string.format("%s/index.json", package_name:lower())
	local decoded = curl_sync(url)
	if not decoded then
		print("Failed to fetch package versions")
		return {}
	end

	local versions = map(decoded.versions, parse_version)
	table.sort(versions, function(a, b)
		return compare_versions(b, a)
	end)
	_package_versions_cache[package_name] = versions
	return versions
end

---@param package_name string
---@param callback fun(v: NuGetVersion[]): nil
---@return nil
local function get_package_versions(package_name, callback)
	if _package_versions_cache[package_name] ~= nil then
		callback(_package_versions_cache[package_name])
	end

	local function handle(base)
		local url = base .. string.format("%s/index.json", package_name:lower())
		local function handle2(decoded)
			if not decoded then
				print("Failed to fetch package versions")
				callback({})
			end

			local versions = map(decoded.versions, parse_version)
			table.sort(versions, function(a, b)
				return compare_versions(b, a)
			end)
			_package_versions_cache[package_name] = versions
			callback(versions)
		end
		curl(url, handle2)
	end
	get_package_base_addr(handle)
end

---@param version NuGetVersion
---@return nil
local function update_package_version(version)
	local line = vim.api.nvim_get_current_line()
	local new_line = line:gsub('Version="[^"]+"', string.format('Version="%s"', nuGetVersionToString(version)))
	vim.api.nvim_set_current_line(new_line)
end

-- A map from package to { packageWeDependOn: version }.
--- @type table<string, table<string, string>>
local _package_dependency_cache = {}
---@param package_name string
---@param version NuGetVersion
---@param callback fun(result: table<string, string>): nil
---@return nil
local function get_package_dependencies(package_name, version, callback)
	local key = package_name .. "@" .. nuGetVersionToString(version)
	local cache_hit = _package_dependency_cache[key]
	if cache_hit ~= nil then
		callback(cache_hit)
		return
	end

	local function handle1(index)
		local url = index .. string.format("%s/%s.json", package_name:lower(), nuGetVersionToString(version):lower())

		local function handle(response)
			if not response then
				print(
					"Failed to get dependencies of "
						.. package_name
						.. " at version "
						.. version
						.. " : unsuccessful response to "
						.. url
				)
				return
			end

			local entry_url = response["catalogEntry"]
			local function handle2(catalog_entry)
				if not catalog_entry then
					print(
						"Failed to get dependencies of "
							.. package_name
							.. " at version "
							.. version
							.. " : unsuccessful response to "
							.. entry_url
					)
					return
				end

				local result = {}
				if catalog_entry["dependencyGroups"] then
					iter(catalog_entry["dependencyGroups"], function(grp)
						if grp["dependencies"] then
							for _, dep in pairs(grp["dependencies"]) do
								result[dep["id"]] = dep["range"]
							end
						end
					end)
				end

				_package_dependency_cache[key] = result

				callback(result)
			end
			curl(entry_url, handle2)
		end

		curl(url, handle)
	end

	get_nuget_index(handle1)
end

---@return table<string, NuGetVersion>
---@nodiscard
local function get_all_package_references()
	local packages = {}
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	for _, line in ipairs(lines) do
		local package_name = line:match('PackageReference Include="([^"]+)"')
			or line:match('PackageReference Update="([^"]+)"')
		local version = line:match('Version="([^"]+)"')

		if package_name and version then
			if not packages[package_name] then
				packages[package_name] = {}
			end
			table.insert(packages[package_name], parse_version(version))
		end
	end

	return packages
end

function ClearNuGetDependencyCache()
	for k, _ in pairs(_package_dependency_cache) do
		_package_dependency_cache[k] = nil
	end
end
vim.api.nvim_create_user_command("ClearNuGetDependencyCache", ClearNuGetDependencyCache, {})

function PrintNuGetDependencyCache()
	for k, v in pairs(_package_dependency_cache) do
		print(k .. ":")
		for dep, ver in pairs(v) do
			print("  " .. dep .. ": " .. ver)
		end
	end
end
vim.api.nvim_create_user_command("PrintNuGetDependencyCache", PrintNuGetDependencyCache, {})

local function prefetch_dependencies()
	local packages = get_all_package_references()

	local function process_package(package_name, versions, callback)
		local count = #versions
		for _, version in ipairs(versions) do
			vim.schedule(function()
				get_package_dependencies(package_name, version, function(_)
					count = count - 1
					if count == 0 then
						callback()
					end
				end)
			end)
		end
	end

	local total_packages = 0
	for _ in pairs(packages) do
		total_packages = total_packages + 1
	end

	local processed_packages = 0
	for package_name, versions in pairs(packages) do
		process_package(package_name, versions, function()
			local function handle(package_versions)
				if package_versions then
					process_package(package_name, package_versions, function()
						processed_packages = processed_packages + 1
						if processed_packages == total_packages then
							print("All dependencies prefetched")
						end
					end)
				else
					processed_packages = processed_packages + 1
					if processed_packages == total_packages then
						print("All dependencies prefetched")
					end
				end
			end
			get_package_versions(package_name, handle)
		end)
	end
end

---@param v1 NuGetVersion
---@param v2 NuGetVersion
---@return boolean
---@nodiscard
local function nuget_versions_equal(v1, v2)
	return v1.major == v2.major and v1.minor == v2.minor and v1.patch == v2.patch and v1.suffix == v2.suffix
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "fsharp_project", "csharp_project", "xml" },
	callback = function()
		function UpdateNuGetVersion()
			local line = vim.api.nvim_get_current_line()
			local package_name = line:match('PackageReference Include="([^"]+)"')
				or line:match('PackageReference Update="([^"]+)"')

			if not package_name then
				print("No package reference found on the current line")
				return
			end

			local current_version = parse_version(line:match('Version="([^"]+)"'))
			if not current_version then
				print("oh no!")
			end

			local package_versions = get_package_versions_sync(package_name)

			if #package_versions == 0 then
				print("No versions found for the package")
				return
			end

			local pickers = require("telescope.pickers")
			local finders = require("telescope.finders")
			local previewers = require("telescope.previewers")

			pickers
				.new({}, {
					prompt_title = string.format("Select version for %s", package_name),
					finder = finders.new_table({
						results = package_versions,
						entry_maker = function(entry)
							local val = nuGetVersionToString(entry)
							local display_value = val
							if current_version and nuget_versions_equal(entry, current_version) then
								display_value = "[CURRENT] " .. val
							end
							return {
								value = entry,
								display = display_value,
								ordinal = entry,
							}
						end,
					}),
					previewer = previewers.new_buffer_previewer({
						define_preview = function(self, entry, _)
							local bufnr = self.state.bufnr
							vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Loading..." })
							get_package_dependencies(package_name, entry.value, function(package_dependencies)
								if not package_dependencies then
									vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "No dependencies found" })
									return
								end

								local display = {}
								table.insert(
									display,
									"Dependencies for "
										.. package_name
										.. " at version "
										.. nuGetVersionToString(entry.value)
										.. ":"
								)
								for dep, range in pairs(package_dependencies) do
									table.insert(display, dep .. ": " .. range)
								end
								local ok, err = pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, display)
								if not ok then
									-- If we can't set lines, the window's probably gone. Ignore.
									return
								end
							end)
						end,
					}),
					attach_mappings = function(_, mapping)
						mapping("i", "<CR>", function(prompt_bufnr)
							local selection = require("telescope.actions.state").get_selected_entry()
							require("telescope.actions").close(prompt_bufnr)
							update_package_version(selection.value)
						end)
						return true
					end,
				})
				:find()
		end
		local whichkey = require("which-key")
		whichkey.add({
			{ "<localleader>n", desc = "NuGet" },
			{ "<localleader>nu", UpdateNuGetVersion, desc = "Upgrade NuGet versions" },
		}, { buffer = vim.api.nvim_get_current_buf() })

		vim.schedule(prefetch_dependencies)
	end,
})
