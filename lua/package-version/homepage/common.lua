local M = {}

local OS_LINUX = "Linux"
local OS_DARWIN = "Darwin"
local OS_WINDOWS = "Windows"

---@param url string
M.open_url = function(url)
	local logger = require("package-version.utils.logger")
	local os_name = vim.uv.os_uname().sysname
	local cmd

	if os_name == OS_DARWIN then
		cmd = { "open", url }
	elseif os_name == OS_LINUX then
		cmd = { "xdg-open", url }
	elseif os_name:match(OS_WINDOWS) then
		cmd = { "cmd", "/c", "start", url }
	else
		logger.error("Unsupported operating system: " .. os_name)
		return
	end

	vim.fn.jobstart(cmd, { detach = true })
end

return M
