local M = {}

function M.setup(opts)
	-- Load and setup configurations
	local config = require("nvim-ruby-debugger.config")
	config.setup(opts)

	-- Setup DAP
	local status_dap, dap = pcall(require, "dap")
	if not status_dap then
		vim.notify("nvim-dap is not installed", vim.log.levels.ERROR)
		return
	end

	-- Setup DAP UI
	local status_dapui, dapui = pcall(require, "dapui")
	if not status_dapui then
		vim.notify("nvim-dap-ui is not installed", vim.log.levels.ERROR)
		return
	end

	-- Setup DAP Virtual Text
	local status_dap_virtual_text, dap_virtual_text = pcall(require, "nvim-dap-virtual-text")
	if not status_dap_virtual_text then
		vim.notify("nvim-dap-virtual-text is not installed", vim.log.levels.ERROR)
		return
	end

	-- Configure DAP
	dap.adapters.ruby = function(callback, conf)
		callback({
			type = "server",
			host = conf.host or config.options.host,
			port = conf.port or config.options.port,
		})
	end

	dap.configurations.ruby = {
		{
			type = "ruby",
			name = "Rails server",
			request = "attach",
			port = config.options.port,
			server = config.options.host,
			options = {
				source_filetype = "ruby",
			},
			cwd = config.get_rails_root,
			remoteWorkspaceRoot = config.get_rails_root,
		},
	}

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

	-- Setup commands
	vim.api.nvim_create_user_command("RubyDebugConnect", function()
		dap.continue()
	end, {})

	-- Setup keymaps
	config.setup_keymaps()

	vim.notify("Ruby debugger setup complete", vim.log.levels.INFO)
end

return M
