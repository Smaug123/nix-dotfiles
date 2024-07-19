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
	whichkey.register({
		s = {
			name = ".NET solution",
			b = { BuildDotNetSolution, "Build .NET solution" },
			t = { TestDotNetSolution, "Test .NET solution" },
		},
	}, { prefix = vim.api.nvim_get_var("maplocalleader"), buffer = vim.api.nvim_get_current_buf() })
end

local function find_nearest_slns()
	local path = vim.fn.expand("%:p:h") -- Get the full path of the current buffer's directory

	while path and path ~= "/" do
		local sln_paths = vim.fn.glob(path .. "/*.sln", nil, true)
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
		print("No .sln file found in any parent directory.")
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
	pattern = "*.sln",
	callback = function()
		if GetCurrentSln() == nil then
			RegisterSolution(vim.fn.expand("%:p"))
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "fsharp", "cs" },
	callback = function()
		FindAndRegisterSolution(false)
	end,
})

local function compare_versions(a, b)
	local function parse_version(v)
		local major, minor, patch, pre = v:match("(%d+)%.(%d+)%.(%d+)(.*)$")
		return {
			tonumber(major) or 0,
			tonumber(minor) or 0,
			tonumber(patch) or 0,
			pre or "",
		}
	end

	local va, vb = parse_version(a), parse_version(b)

	for i = 1, 3 do
		if va[i] ~= vb[i] then
			return va[i] < vb[i]
		end
	end

	if va[4] == "" and vb[4] ~= "" then
		return false
	end
	if va[4] ~= "" and vb[4] == "" then
		return true
	end
	return va[4] < vb[4]
end

local function get_package_versions(package_name)
	local url = string.format("https://api.nuget.org/v3-flatcontainer/%s/index.json", package_name:lower())
	local command = string.format("_CURL_ --silent --fail '%s'", url)
	local response = vim.fn.system(command)

	if vim.v.shell_error ~= 0 then
		print("Failed to fetch package versions")
		return {}
	end

	local success, decoded = pcall(vim.fn.json_decode, response)
	if not success or not decoded.versions then
		print("Failed to parse package versions")
		return {}
	end

	local versions = decoded.versions
	table.sort(versions, function(a, b)
		return compare_versions(b, a)
	end)
	return versions
end

local function update_package_version(version)
	local line = vim.api.nvim_get_current_line()
	local new_line = line:gsub('Version="[^"]+"', string.format('Version="%s"', version))
	vim.api.nvim_set_current_line(new_line)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "fsharp_project", "csharp_project" },
	callback = function()
		function UpdateNuGetVersion()
			local line = vim.api.nvim_get_current_line()
			local package_name = line:match('PackageReference Include="([^"]+)"')
				or line:match('PackageReference Update="([^"]+)"')
			local current_version = line:match('Version="([^"]+)"')

			if not package_name then
				print("No package reference found on the current line")
				return
			end

			local package_versions = get_package_versions(package_name)

			if #package_versions == 0 then
				print("No versions found for the package")
				return
			end

			local pickers = require("telescope.pickers")
			local finders = require("telescope.finders")
			local conf = require("telescope.config").values

			pickers
				.new({}, {
					prompt_title = string.format("Select version for %s", package_name),
					finder = finders.new_table({
						results = package_versions,
						entry_maker = function(entry)
							local display_value = entry
							if current_version and entry == current_version then
								display_value = "[CURRENT] " .. entry
							end
							return {
								value = entry,
								display = display_value,
								ordinal = entry,
							}
						end,
					}),
					sorter = conf.generic_sorter({}),
					attach_mappings = function(_, map)
						map("i", "<CR>", function(prompt_bufnr)
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
		whichkey.register({
			n = {
				name = "NuGet",
				u = { UpdateNuGetVersion, "Upgrade NuGet versions" },
			},
		}, { prefix = vim.api.nvim_get_var("maplocalleader"), buffer = vim.api.nvim_get_current_buf() })
	end,
})
