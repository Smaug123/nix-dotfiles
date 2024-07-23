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

---@param v string
---@nodiscard
---@return NuGetVersion
local function parse_version(v)
	local major, minor, patch, pre = v:match("(%d+)%.(%d+)%.(%d+)(.*)$")
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

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "fsharp_project", "csharp_project" },
	callback = function()
		function UpdateNuGetVersion()
			local line = vim.api.nvim_get_current_line()
			local package_name = line:match('PackageReference Include="([^"]+)"')
				or line:match('PackageReference Update="([^"]+)"')
			local current_version = nuGetVersionToString(line:match('Version="([^"]+)"'))

			if not package_name then
				print("No package reference found on the current line")
				return
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
							if current_version and entry == current_version then
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
								vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, display)
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
		whichkey.register({
			n = {
				name = "NuGet",
				u = { UpdateNuGetVersion, "Upgrade NuGet versions" },
			},
		}, { prefix = vim.api.nvim_get_var("maplocalleader"), buffer = vim.api.nvim_get_current_buf() })

		vim.schedule(prefetch_dependencies)
	end,
})
