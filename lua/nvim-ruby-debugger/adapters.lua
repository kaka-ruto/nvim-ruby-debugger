-- Adapters for the plugin

local M = {}

function M.setup(dap, config)
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
end

return M
