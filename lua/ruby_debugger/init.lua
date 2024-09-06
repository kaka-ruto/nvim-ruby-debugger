local M = {}

M.config = {
	port = 3001,
	host = "127.0.0.1",
	debugger_cmd = { "bundle", "exec", "rdbg", "-n", "--open", "--port", "${port}", "--host", "${host}" },
	log_level = "info",
}

local function notify(msg, level)
	level = level or vim.log.levels.INFO
	vim.notify(msg, level, { title = "Ruby Debugger" })
end

local function log(level, message)
	if
		vim.fn.index({ "error", "warn", "info", "debug" }, level)
		>= vim.fn.index({ "error", "warn", "info", "debug" }, M.config.log_level)
	then
		notify(message, vim.log.levels[level:upper()])
	end
end

local function setup_adapter(dap)
	dap.adapters.ruby = function(callback, config)
		local port = config.port or M.config.port
		local host = config.host or M.config.host
		local debugger_cmd = vim.deepcopy(M.config.debugger_cmd)

		-- Replace placeholders with actual values
		for i, arg in ipairs(debugger_cmd) do
			debugger_cmd[i] = arg:gsub("${port}", tostring(port)):gsub("${host}", host)
		end

		local options = {
			type = "executable",
			command = debugger_cmd[1],
			args = vim.list_slice(debugger_cmd, 2),
		}

		local handle, pid_or_err
		handle, pid_or_err = vim.loop.spawn(options.command, {
			args = options.args,
			detached = false,
		}, function(code)
			handle:close()
			if code ~= 0 then
				notify("Ruby debugger exited with code: " .. code, vim.log.levels.ERROR)
			end
		end)

		if not handle then
			notify("Error running ruby debugger: " .. tostring(pid_or_err), vim.log.levels.ERROR)
			return
		end

		-- Wait for debugger to start
		vim.defer_fn(function()
			callback(options)
		end, 100)

		notify("Ruby debugger started on " .. host .. ":" .. port, vim.log.levels.INFO)
	end
end

local function setup_configuration(dap)
	dap.configurations.ruby = {
		{
			type = "ruby",
			name = "Debug current file",
			request = "launch",
			program = "${file}",
		},
		{
			type = "ruby",
			name = "Attach to Rails",
			request = "attach",
			port = M.config.port,
			host = M.config.host,
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
