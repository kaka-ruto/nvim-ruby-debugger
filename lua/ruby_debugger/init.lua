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
		args = function()
			local args = vim.deepcopy(M.config.debugger_cmd)
			table.remove(args, 1) -- Remove 'bundle'
			table.remove(args, 1) -- Remove 'exec'
			for i, arg in ipairs(args) do
				args[i] = arg:gsub("${port}", tostring(M.config.port)):gsub("${host}", M.config.host)
			end
			return args
		end,
	}
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
