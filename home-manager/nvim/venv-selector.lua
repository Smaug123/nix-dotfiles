local venv_selector = require("venv-selector")

venv_selector.setup({
	changed_venv_hooks = { venv_selector.hooks.pyright },
	name = { "venv", ".venv" },
	search_venv_managers = true,
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
		local context = BuildUtils.create_window()
		BuildUtils.run(
			venv_dir .. "/bin/python",
			{ "-m", "pip", "install", "-r", requirements_path },
			"venv creation",
			context,
			function(_, _, _) end,
			function(_, _, _)
				load_venv(venv_dir)
			end
		)
	else
		load_venv(venv_dir)
	end
end

do
	local whichkey = require("which-key")
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
	}, { prefix = vim.api.nvim_get_var("maplocalleader") })
end
