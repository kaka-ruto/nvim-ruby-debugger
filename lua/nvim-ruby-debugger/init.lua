-- Main entry point for the plugin

local M = {}

function M.setup(opts)
	local config = require("nvim-ruby-debugger.config")
	config.setup(opts)

	local dap = require("dap")
	local dapui = require("dapui")
	local dap_virtual_text = require("nvim-dap-virtual-text")

	require("nvim-ruby-debugger.adapters").setup(dap, config)
	require("nvim-ruby-debugger.configurations").setup(dap, config)
	require("nvim-ruby-debugger.commands").setup(dap, config)

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
