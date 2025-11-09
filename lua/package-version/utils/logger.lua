local M = {}

local title = { title = "package-version.nvim" }

---@param message string
M.debug = function(message)
	vim.notify(message, vim.log.levels.DEBUG, title)
end

---@param message string
M.info = function(message)
	vim.notify(message, vim.log.levels.INFO, title)
end

---@param message string
M.error = function(message)
	vim.notify(message, vim.log.levels.ERROR, title)
end

return M
