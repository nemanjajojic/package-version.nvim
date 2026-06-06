local M = {}

---@param name string
---@return boolean
M.is_container_runing = function(name)
	local handle = io.popen("docker ps --filter 'name=" .. name .. "' --format ' {{.Names}}'")

	if handle == nil then
		return false
	end

	local output = handle:read("*a")

	handle:close()

	return output:find(name) ~= nil
end

return M
