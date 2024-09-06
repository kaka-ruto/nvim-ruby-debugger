local M = {}

M.config = {
	port = 38698,
	host = "127.0.0.1",
	log_level = "info",
	debugger_cmd = { "bundle", "exec", "rdbg" },
	rdbg_options = {
		"--open",
		"--port",
		"${port}",
		"--host",
		"${host}",
		"-c",
		"--",
	},
}

local function log(level, message)
	if
		vim.fn.index({ "error", "warn", "info", "debug" }, level)
		>= vim.fn.index({ "error", "warn", "info", "debug" }, M.config.log_level)
	then
		vim.notify(string.format("[ruby-debugger] %s: %s", level:upper(), message), vim.log.levels[level:upper()])
	end
end

local function setup_adapter(dap)
	dap.adapters.ruby = function(callback, config)
		local port = config.port or M.config.port
		local host = config.host or M.config.host

		log("debug", string.format("Setting up Ruby adapter on %s:%d", host, port))

		local opts = {
			type = "server",
			host = host,
			port = port,
		}

		if config.request ~= "attach" then
			local args = vim.deepcopy(M.config.debugger_cmd)
			vim.list_extend(args, M.config.rdbg_options)
			for i, arg in ipairs(args) do
				args[i] = arg:gsub("${port}", tostring(port)):gsub("${host}", host)
			end
			if config.script and config.script ~= "" then
				vim.list_extend(args, { config.script })
			end
			opts.executable = {
				command = args[1],
				args = vim.list_slice(args, 2),
			}
			log("debug", "Launching debugger with command: " .. vim.inspect(opts.executable))
		end

		callback(opts)
	end
	log("debug", "Ruby adapter setup complete")
end

local function setup_configuration(dap)
	dap.configurations.ruby = {
		{
			type = "ruby",
			name = "Debug current file",
			request = "launch",
			program = "${file}",
			cwd = "${workspaceFolder}",
		},
		{
			type = "ruby",
			name = "Attach to Rails",
			request = "attach",
			remoteHost = M.config.host,
			remotePort = M.config.port,
			remoteWorkspaceRoot = "${workspaceFolder}",
			cwd = "${workspaceFolder}",
		},
		{
			type = "ruby",
			name = "Run RSpec (current file)",
			request = "launch",
			program = "bundle",
			programArgs = { "exec", "rspec", "${file}" },
			cwd = "${workspaceFolder}",
		},
		{
			type = "ruby",
			name = "Debug Rails server",
			request = "launch",
			program = "bundle",
			programArgs = { "exec", "rails", "server" },
			cwd = "${workspaceFolder}",
		},
	}
	log("debug", "Ruby configurations setup complete")
end

function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})

	local status, dap = pcall(require, "dap")
	if not status then
		log("error", "nvim-dap is not installed")
		return
	end

	setup_adapter(dap)
	setup_configuration(dap)

	log("info", "Ruby debug setup complete")
	log("debug", "Final configuration: " .. vim.inspect(M.config))
end

return M
