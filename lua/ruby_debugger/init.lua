local M = {}

M.config = {
	port = 38698,
	host = "127.0.0.1",
	log_level = "info",
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

		local opts = {
			type = "server",
			host = host,
			port = port,
			executable = {
				command = "bundle",
				args = { "exec", "rdbg", "-n", "--open", "--port", tostring(port) },
			},
		}

		if config.request == "attach" then
			opts.executable = nil
		end

		log("debug", "Adapter options: " .. vim.inspect(opts))
		callback(opts)
	end
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
			cwd = "${workspaceFolder}",
		},
		{
			type = "ruby",
			name = "Debug Rails server",
			request = "launch",
			program = "bin/rails",
			programArgs = { "server" },
			cwd = "${workspaceFolder}",
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
	log("debug", "Final configuration: " .. vim.inspect(M.config))
end

return M
