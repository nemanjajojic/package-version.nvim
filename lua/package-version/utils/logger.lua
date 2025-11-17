local M = {}

local title = { title = "package-version.nvim", icon = "📦", timeout = 3000 }

local notify = function(message, level)
	vim.notify(message, level, title)
end

---@param message string
M.debug = function(message)
	notify(message, vim.log.levels.DEBUG)
end

---@param message string
M.info = function(message)
	notify(message, vim.log.levels.INFO)
end

---@param message string
M.warning = function(message)
	notify(message, vim.log.levels.WARN)
end

---@param message string
M.error = function(message)
	notify(message, vim.log.levels.ERROR)
end

return M
