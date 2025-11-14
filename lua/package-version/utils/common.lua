local M = {
	---@type ColorConfig
	color_config = {
		latest = "#a6e3a1",
		wanted = "#f9e2af",
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
M.latest_hl = function()
	local name = "Latest"
	vim.api.nvim_set_hl(0, name, {
		fg = M.color_config.latest,
	})

	return name
end

---@return string
M.wanted_hl = function()
	local name = "Wanted"
	vim.api.nvim_set_hl(0, name, {
		fg = M.color_config.wanted,
	})

	return name
end

---@param line_number integer
---@param package_version string
---@param namespace_id integer
---@param icon string
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

---@param line_content string
---@return string|nil
M.get_package_name_from_line_json = function(line_content)
	return line_content:match('"([^"]+)"%s*:%s*"[%^~]%d+%.%d+%.?%d*"')
end

return M
