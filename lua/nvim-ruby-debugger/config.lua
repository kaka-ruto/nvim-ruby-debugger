local M = {}

M.options = {
	rails_port = 38698,
	worker_port = 38699,
	host = "127.0.0.1",
}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

function M.get_rails_root()
	local current_dir = vim.fn.getcwd()
	while current_dir ~= "/" do
		if vim.fn.filereadable(current_dir .. "/config/application.rb") == 1 then
			return current_dir
		end
		current_dir = vim.fn.fnamemodify(current_dir, ":h")
	end
	return nil
end

function M.setup_keymaps()
	vim.keymap.set("n", "<F5>", function()
		require("dap").continue()
	end)
	vim.keymap.set("n", "<F10>", function()
		require("dap").step_over()
	end)
	vim.keymap.set("n", "<F11>", function()
		require("dap").step_into()
	end)
	vim.keymap.set("n", "<F12>", function()
		require("dap").step_out()
	end)
	vim.keymap.set("n", "<Leader>b", function()
		require("dap").toggle_breakpoint()
	end)
	vim.keymap.set("n", "<Leader>B", function()
		require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
	end)
	vim.keymap.set("n", "<Leader>lp", function()
		require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
	end)
	vim.keymap.set("n", "<Leader>dr", function()
		require("dap").repl.open()
	end)
end

return M
