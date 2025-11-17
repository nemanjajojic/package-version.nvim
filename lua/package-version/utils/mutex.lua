local M = {}

local logger = require("package-version.utils.logger")

local is_operation_running = false
local current_operation = nil

---@param operation_name string
---@return boolean succes
M.try_lock = function(operation_name)
	if is_operation_running then
		logger.warning(
			string.format(
				"Cannot start '%s' - another operation is already running: %s",
				operation_name,
				current_operation or "unknown"
			)
		)

		return false
	end

	is_operation_running = true

	current_operation = operation_name

	return true
end

M.unlock = function()
	is_operation_running = false

	current_operation = nil
end

---@return boolean
M.is_locked = function()
	return is_operation_running
end

---@return string|nil
M.get_current_operation = function()
	return current_operation
end

return M
