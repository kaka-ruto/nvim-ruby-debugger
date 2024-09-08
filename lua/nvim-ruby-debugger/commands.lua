-- User commands for starting the debugger

local M = {}

local utils = require("nvim-ruby-debugger.utils")

function M.setup(dap, config)
	vim.api.nvim_create_user_command("DebugRailsServer", function()
		dap.run(dap.configurations.ruby[1])
	end, {})

	vim.api.nvim_create_user_command("DebugSolidQueueWorker", function()
		dap.run(dap.configurations.ruby[2])
	end, {})

	vim.api.nvim_create_user_command("DebugMinitestFile", function()
		if not utils.is_port_available(config.options.minitest_port) then
			print(
				"Port "
					.. config.options.minitest_port
					.. " is already in use. Please choose a different port or stop the process using this port."
			)
			return
		end
		dap.run(dap.configurations.ruby[3])
	end, {})

	vim.api.nvim_create_user_command("DebugMinitestLine", function()
		local config = dap.configurations.ruby[4] -- Make sure this index is correct
		dap.run(config)
	end, {})
end

return M
