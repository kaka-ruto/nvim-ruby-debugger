local M = {}

function M.setup(opts)
	local config = require("nvim-ruby-debugger.config")
	config.setup(opts)

	local dap = require("dap")
	local dapui = require("dapui")
	local dap_virtual_text = require("nvim-dap-virtual-text")

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
	}

	dap.adapters.ruby = function(callback, config)
		if config.request == "attach" and config.command then
			local handle
			local pid_or_err
			local stdout = vim.loop.new_pipe(false)
			local stderr = vim.loop.new_pipe(false)

			handle, pid_or_err = vim.loop.spawn(config.command, {
				args = config.commandArgs,
				cwd = config.cwd,
				stdio = { nil, stdout, stderr },
				detached = true,
			}, function(code)
				stdout:close()
				stderr:close()
				handle:close()
				if code ~= 0 then
					print("rdbg exited with code", code)
				end
			end)

			if not handle then
				error("Unable to spawn rdbg: " .. tostring(pid_or_err))
			end

			vim.loop.read_start(stdout, function(err, data)
				assert(not err, err)
				if data then
					print("rdbg stdout: " .. data)
				end
			end)

			vim.loop.read_start(stderr, function(err, data)
				assert(not err, err)
				if data then
					print("rdbg stderr: " .. data)
				end
			end)

			vim.defer_fn(function()
				callback({
					type = "server",
					host = config.server,
					port = config.port,
				})
			end, config.waiting or 1000)
		else
			callback({
				type = "server",
				host = config.server,
				port = config.port,
			})
		end
	end

	-- Command to debug Rails server
	vim.api.nvim_create_user_command("DebugRailsServer", function()
		dap.run(dap.configurations.ruby[1])
	end, {})

	-- Command to debug Solid Queue worker
	vim.api.nvim_create_user_command("DebugSolidQueueWorker", function()
		dap.run(dap.configurations.ruby[2])
	end, {})

	-- Configure DAP UI
	dapui.setup()

	-- Configure DAP Virtual Text
	dap_virtual_text.setup({
		enabled = true,
		enabled_commands = true,
		highlight_changed_variables = true,
		highlight_new_as_changed = false,
		show_stop_reason = true,
		commented = false,
		only_first_definition = true,
		all_references = false,
		filter_references_pattern = "<module",
		virt_text_pos = "eol",
		all_frames = false,
		virt_lines = false,
		virt_text_win_col = nil,
	})

	-- Setup DAP listeners for UI
	dap.listeners.after.event_initialized["dapui_config"] = function()
		dapui.open()
	end
	dap.listeners.before.event_terminated["dapui_config"] = function()
		dapui.close()
	end
	dap.listeners.before.event_exited["dapui_config"] = function()
		dapui.close()
	end

	-- Setup keymaps
	config.setup_keymaps()

	vim.notify("Ruby debugger setup complete", vim.log.levels.INFO)
end

return M
