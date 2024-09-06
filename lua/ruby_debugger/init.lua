local M = {}

M.config = {
	default_port = 38698, -- Default port used by rdbg
	host = "127.0.0.1",
	log_level = "info",
	debugger_cmd = { "bundle", "exec", "rdbg" },
	debuginfod = false, -- Enable debuginfod support
	rdbg_options = {
		"--no-sigint-hook", -- Recommended for use with Neovim
		"--no-use-script-lines", -- Improves performance
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
		local port = config.port or M.config.default_port
		local args = vim.list_extend(vim.deepcopy(M.config.debugger_cmd), { "-n", "--open", "--port", tostring(port) })
		vim.list_extend(args, M.config.rdbg_options)
		if M.config.debuginfod then
			table.insert(args, "--debuginfod")
		end
		if config.command and config.script then
			vim.list_extend(args, { "-c", "--", "bundle", "exec", config.command, config.script })
		end

		callback({
			type = "server",
			host = M.config.host,
			port = port,
			executable = {
				command = args[1],
				args = vim.list_slice(args, 2),
			},
		})
	end
	log("debug", "Ruby adapter setup complete")
end

local function setup_configuration(dap)
	dap.configurations.ruby = {
		{
			type = "ruby",
			name = "Debug current file",
			request = "attach",
			localfs = true,
			command = "ruby",
			script = "${file}",
		},
		{
			type = "ruby",
			name = "Run current spec file",
			request = "attach",
			localfs = true,
			command = "rspec",
			script = "${file}",
		},
		{
			type = "ruby",
			name = "Debug Rails",
			request = "attach",
			localfs = true,
			command = "rails",
			script = "server",
		},
		{
			type = "ruby",
			name = "Attach to existing process",
			request = "attach",
			pid = function()
				return vim.fn.input("PID: ")
			end,
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
