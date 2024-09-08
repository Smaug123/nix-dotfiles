local function pytest_on_line(_, _, _) end
local function pytest_on_complete(_, code, _)
	if code ~= 0 then
		print("Exit code " .. code)
	end
end

function RunPythonTestAtCursor()
	local api = vim.api

	-- Get the current buffer and cursor position
	local bufnr = api.nvim_get_current_buf()
	local line_nr = api.nvim_win_get_cursor(0)[1]
	local filename = api.nvim_buf_get_name(bufnr)

	-- Read the file content
	local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

	-- Find the test function
	local test_name = nil
	for i = line_nr, 1, -1 do
		local line = lines[i]
		if line:match("^def test_") then
			test_name = line:match("^def (%S+)%(")
			break
		end
	end

	if test_name then
		-- Run pytest for the found test function
		local context = BuildUtils.create_window()
		BuildUtils.run(
			"pytest",
			{ filename .. "::" .. test_name },
			"Run PyTest (" .. test_name .. ")",
			context,
			pytest_on_line,
			pytest_on_complete
		)
	else
		print("No test function found at or above line " .. line_nr)
	end
end

function RunPythonTestsInFile()
	local file_path = vim.fn.expand("%:p")
	local context = BuildUtils.create_window()
	BuildUtils.run("pytest", { file_path }, "Run PyTest", context, pytest_on_line, pytest_on_complete)
end

function RunAllPythonTests()
	local context = BuildUtils.create_window()
	BuildUtils.run("pytest", {}, "Run PyTest", context, pytest_on_line, pytest_on_complete)
end

do
	local whichkey = require("which-key")
	whichkey.add({
		{ "<localleader>pt", desc = "Run Python tests" },
		{ "<localleader>ptf", RunPythonTestsInFile, desc = "Run Python tests in the current file" },
		{ "<localleader>pta", RunAllPythonTests, desc = "Run all Python tests" },
		{ "<localleader>ptc", RunPythonTestAtCursor, desc = "Run the Python test under the cursor" },
	})
end
