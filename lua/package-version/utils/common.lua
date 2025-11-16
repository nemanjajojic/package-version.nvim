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
---@param style string|nil
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
	-- Match dependency patterns only - version string must start with valid version characters
	-- Valid patterns: "1.0.0", "^1.0.0", "~1.0.0", ">=1.0.0", "*", "latest", "workspace:*", etc.
	-- Excludes script commands like "npx tsc", "node index.js", etc.

	-- Match version starting with version range characters or digits
	local package_name = line_content:match('"([^"]+)"%s*:%s*"[~^>=<*0-9][^"]*"')
	if package_name then
		return package_name
	end

	-- Match workspace protocol (e.g., "workspace:*", "workspace:^1.0.0")
	package_name = line_content:match('"([^"]+)"%s*:%s*"workspace:[^"]*"')
	if package_name then
		return package_name
	end

	-- Match npm tags like "latest", "next", "canary" - use alternation in value check
	if
		line_content:match('%s*:%s*"latest"')
		or line_content:match('%s*:%s*"next"')
		or line_content:match('%s*:%s*"canary"')
		or line_content:match('%s*:%s*"beta"')
		or line_content:match('%s*:%s*"alpha"')
	then
		package_name = line_content:match('"([^"]+)"%s*:%s*"[^"]*"')
		return package_name
	end

	return nil
end

return M
