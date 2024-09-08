-- Adapter configurations for Ruby debugger

local M = {}

local function get_test_command(file, line)
	local cmd = {}
	if line then
		table.insert(cmd, file .. ":" .. line)
	else
		table.insert(cmd, file)
	end
	return cmd
end

local function create_minitest_config(name, get_args, config)
	return {
		type = "ruby",
		name = name,
		request = "attach",
		command = "bundle",
		commandArgs = function()
			local args = {
				"exec",
				"rdbg",
				"-n",
				"--open",
				"--port",
				tostring(config.options.minitest_port),
				"-c",
				"--",
				"bin/rails",
				"test",
			}
			local test_cmd = get_args()
			for _, arg in ipairs(test_cmd) do
				table.insert(args, arg)
			end
			return args
		end,
		port = config.options.minitest_port,
		server = config.options.host,
		cwd = config.get_rails_root,
		env = {
			["RAILS_ENV"] = "test",
		},
		localfs = true,
	}
end

function M.setup(dap, config)
	dap.configurations.ruby = {
		{
			type = "ruby",
			name = "Rails server",
			request = "attach",
			port = config.options.rails_port,
			server = config.options.host,
			options = {
				source_filetype = "ruby",
			},
			cwd = config.get_rails_root,
			localfs = true,
		},
		{
			type = "ruby",
			name = "Solid Queue Worker",
			request = "attach",
			command = "bundle",
			commandArgs = {
				"exec",
				"rdbg",
				"-n",
				"--open",
				"--port",
				tostring(config.options.worker_port),
				"-c",
				"--",
				"bin/jobs",
				"start",
			},
			port = config.options.worker_port,
			server = config.options.host,
			options = {
				source_filetype = "ruby",
			},
			cwd = config.get_rails_root,
			localfs = true,
			waiting = 1000,
		},
		create_minitest_config("Minitest - Current File", function()
			local file = vim.fn.expand("%:p")
			return get_test_command(file)
		end, config),
		create_minitest_config("Minitest - Current Line", function()
			local file = vim.fn.expand("%:p")
			local line = vim.fn.line(".")
			return get_test_command(file, line)
		end, config),
	}
end

return M
