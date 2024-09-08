-- For utility functions

local M = {}

function M.is_port_available(port)
	local handle = io.popen(string.format("lsof -i :%d", port))
	local result = handle:read("*a")
	handle:close()
	return result == ""
end

return M
