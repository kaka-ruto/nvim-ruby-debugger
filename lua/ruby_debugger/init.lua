local M = {}

M.config = {
	port = 3001,
	host = "127.0.0.1",
	debugger_cmd = "bundle exec rdbg -n --open --port ${port} --host ${host}",
	log_level = "info",
}

local function log(level, message)
	if
		vim.fn.index({ "error", "warn", "info", "debug" }, level)
		>= vim.fn.index({ "error", "warn", "info", "debug" }, M.config.log_level)
	then
		vim.notify(string.format("[ruby-debug] %s: %s", level:upper(), message), vim.log.levels[level:upper()])
	end
end

local function setup_adapter(dap)
	dap.adapters.ruby = function(callback, config)
		local stdout = vim.loop.new_pipe(false)
		local handle
		local pid_or_err
		local port = config.port or M.config.port
		local host = config.host or M.config.host
		local debugger_cmd = config.debugger_cmd or M.config.debugger_cmd

		debugger_cmd = debugger_cmd:gsub("${port}", tostring(port)):gsub("${host}", host)

		local opts = {
			stdio = { nil, stdout },
			args = {},
			detached = true,
		}

		handle, pid_or_err = vim.loop.spawn("sh", opts, function(code)
			stdout:close()
			handle:close()
			if code ~= 0 then
				log("error", string.format("ruby debugger exited with code %d", code))
			end
		end)

		assert(handle, "Error running ruby debugger: " .. tostring(pid_or_err))

		stdout:read_start(function(err, chunk)
			assert(not err, err)
			if chunk then
				log("debug", chunk)
			end
		end)

		vim.loop.write(handle, debugger_cmd .. "\n")

		-- Wait for debugger to start
		vim.defer_fn(function()
			callback({ type = "server", host = host, port = port })
		end, 1000)

		log("info", string.format("Ruby debugger started on %s:%d", host, port))
	end
end

local function setup_configuration(dap)
	dap.configurations.ruby = {
		{
			type = "ruby",
			name = "Rails Debug",
			request = "attach",
			port = M.config.port,
			host = M.config.host,
			debugger_cmd = M.config.debugger_cmd,
			localfs = true,
			options = {
				source_filetype = "ruby",
			},
			cwd = vim.fn.getcwd(),
			remoteWorkspaceRoot = vim.fn.getcwd(),
		},
	}
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
end

return M
