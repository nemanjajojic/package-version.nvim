local logger = require("package-version.utils.logger")
local M = {
	---@type ColorConfig
	color_config = {
		major = "#eba0ac",
		minor = "#f9e2af",
		up_to_date = "#a6e3a1",
		current = "Comment",
		abandoned = "#eba0ac",
	},
}

---@return string
M.abandoned_hl = function()
	local name = "Abandoned"
	vim.api.nvim_set_hl(0, name, {
		fg = M.color_config.abandoned,
	})

	return name
end

---@return string
M.major_hl = function()
	local name = "Major"
	vim.api.nvim_set_hl(0, name, {
		fg = M.color_config.major,
	})

	return name
end

---@return string
M.minor_hl = function()
	local name = "Minor"
	vim.api.nvim_set_hl(0, name, {
		fg = M.color_config.minor,
	})

	return name
end

---@return string
M.up_to_date_hl = function()
	local name = "UpToDate"
	vim.api.nvim_set_hl(0, name, {
		fg = M.color_config.up_to_date,
	})

	return name
end

M.set_virtual_text = function(line_number, package_version, namespace_id, icon, style)
	vim.api.nvim_buf_set_extmark(0, namespace_id, line_number - 1, 0, {
		virt_text = {
			{
				" " .. icon .. " " .. package_version .. " ",
				style,
			},
		},
		virt_text_pos = "eol",
	})
end

---@param package_config? PackageVersionConfig
---@return ColorConfig
M.get_default_color_config = function(package_config)
	---@type ColorConfig
	local color = package_config and package_config.color or {}

	color = vim.tbl_extend("force", M.color_config, color)

	return color
end

---@param package_config? PackageVersionConfig
---@return DockerConfig|nil
M.get_docker_config = function(package_config)
	---@type DockerConfig|nil
	local docker_config = package_config and package_config.docker or nil

	if docker_config == nil then
		return nil
	end

	return docker_config
end

---@param package_name string
---@return integer?
M.get_current_line_number = function(package_name)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	for line_number, line_content in ipairs(lines) do
		if package_name == nil then
			goto continue
		end

		if string.find(line_content, '"' .. package_name .. '":', 1, true) then
			return line_number
		end

		::continue::
	end

	return nil
end

return M
