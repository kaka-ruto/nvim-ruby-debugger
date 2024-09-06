local M = {}

M.config = {
	port = 38698,
	host = "127.0.0.1",
	log_level = "debug",
}

local function log(level, message)
	if
		vim.fn.index({ "error", "warn", "info", "debug" }, level)
		>= vim.fn.index({ "error", "warn", "info", "debug" }, M.config.log_level)
	then
		vim.notify(string.format("[ruby-debugger] %s: %s", level:upper(), message), vim.log.levels[level:upper()])
	end
end

local function get_rails_root()
	local current_dir = vim.fn.getcwd()
	while current_dir ~= "/" do
		if vim.fn.filereadable(current_dir .. "/config/application.rb") == 1 then
			return current_dir
		end
		current_dir = vim.fn.fnamemodify(current_dir, ":h")
	end
	return nil
end

local function setup_adapter(dap)
	dap.adapters.ruby = function(callback, config)
		local rails_root = get_rails_root()
		if not rails_root then
			log("error", "Could not find Rails root directory")
			return
		end

		local opts = {
			type = "server",
			host = config.host or M.config.host,
			port = config.port or M.config.port,
			executable = {
				command = "bundle",
				args = {
					"exec",
					"rdbg",
					"-n",
					"--open",
					"--port",
					tostring(config.port or M.config.port),
					"-c",
					"--",
					"bundle",
					"exec",
					"rails",
					"server",
				},
			},
			options = {
				source_filetype = "ruby",
			},
			enrich_config = function(c, on_config)
				c.cwd = rails_root
				c.remoteRoot = rails_root
				on_config(c)
			end,
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
			cwd = get_rails_root,
		},
		{
			type = "ruby",
			name = "Attach to Rails",
			request = "attach",
			remoteHost = M.config.host,
			remotePort = M.config.port,
			remoteWorkspaceRoot = get_rails_root,
			cwd = get_rails_root,
		},
		{
			type = "ruby",
			name = "Debug Rails server",
			request = "launch",
			program = "bin/rails",
			programArgs = { "server" },
			cwd = get_rails_root,
		},
		{
			type = "ruby",
			name = "Run RSpec (current file)",
			request = "launch",
			program = "bundle",
			programArgs = function()
				return { "exec", "rspec", vim.fn.expand("%:p") }
			end,
			cwd = get_rails_root,
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
	log("debug", "Final configuration: " .. vim.inspect(dap.configurations.ruby))
end

M.get_rails_root = get_rails_root

return M
