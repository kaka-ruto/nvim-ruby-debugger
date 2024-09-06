local M = {}

M.config = {
	port = 3001,
	host = "127.0.0.1",
	debugger_cmd = { "bundle", "exec", "rdbg", "-n", "--open", "--port", "${port}", "--host", "${host}" },
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
	dap.adapters.ruby = {
		type = "executable",
		command = "bundle",
		args = { "exec", "rdbg", "-n", "--open", "--port", "${port}", "--host", "${host}" },
	}
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
