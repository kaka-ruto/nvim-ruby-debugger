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
	connection_timeout = 5000, -- 5 seconds
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
		local adapter = {
			type = "server",
			host = config.host or M.config.host,
			port = config.port or M.config.port,
			executable = {
				command = M.config.debugger_cmd[1],
				args = vim.tbl_map(function(arg)
					return arg:gsub("${port}", tostring(config.port or M.config.port))
						:gsub("${host}", config.host or M.config.host)
				end, vim.list_extend(vim.list_slice(M.config.debugger_cmd, 2), M.config.rdbg_options)),
			},
		}

		if config.request == "attach" then
			adapter.executable = nil
		elseif config.rdbg_connection_method == "stdio" then
			adapter.type = "pipe"
			adapter.pipe = nil
		elseif config.rdbg_connection_method == "unix_socket" then
			adapter.type = "server"
			adapter.host = nil
			adapter.port = nil
			adapter.executable.args = vim.tbl_filter(function(arg)
				return not arg:match("^%-%-port") and not arg:match("^%-%-host")
			end, adapter.executable.args)
			table.insert(adapter.executable.args, "--sock")
			table.insert(adapter.executable.args, config.unix_socket_path or "/tmp/ruby-debug-sock")
		end

		if config.script and config.script ~= "" then
			vim.list_extend(adapter.executable.args, { config.script })
		end

		log("debug", "Launching debugger with adapter: " .. vim.inspect(adapter))

		local handle
		local pid_or_err
		local stdout = vim.loop.new_pipe(false)
		local stderr = vim.loop.new_pipe(false)

		local function cleanup()
			stdout:close()
			stderr:close()
			if handle then
				handle:close()
			end
		end

		if adapter.executable then
			handle, pid_or_err = vim.loop.spawn(adapter.executable.command, {
				args = adapter.executable.args,
				stdio = { nil, stdout, stderr },
				detached = true,
			}, function(code)
				cleanup()
				if code ~= 0 then
					log("error", string.format("Debugger exited with code: %d", code))
				end
			end)

			if not handle then
				log("error", "Failed to start debugger: " .. tostring(pid_or_err))
				return
			end

			vim.loop.read_start(stdout, function(err, data)
				assert(not err, err)
				if data then
					log("debug", "Debugger stdout: " .. data)
				end
			end)

			vim.loop.read_start(stderr, function(err, data)
				assert(not err, err)
				if data then
					log("error", "Debugger stderr: " .. data)
				end
			end)
		end

		-- Wait for the debugger to be ready
		vim.defer_fn(function()
			callback(adapter)
		end, 100)
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
