local M = {}
local config_validator = require("package-version.config")

---@param color_config ColorConfig
---@return string
M.abandoned_hl = function(color_config)
	local name = "Abandoned"
	local color = color_config.abandoned

	if not color then
		return name
	end

	if color:sub(1, 1) == "#" then
		vim.api.nvim_set_hl(0, name, { fg = color })
	else
		vim.api.nvim_set_hl(0, name, { link = color })
	end

	return name
end

---@param color_config ColorConfig
---@return string
M.latest_hl = function(color_config)
	local name = "Latest"
	local color = color_config.latest

	if not color then
		return name
	end

	if color:sub(1, 1) == "#" then
		vim.api.nvim_set_hl(0, name, { fg = color })
	else
		vim.api.nvim_set_hl(0, name, { link = color })
	end

	return name
end

---@param color_config ColorConfig
---@return string
M.wanted_hl = function(color_config)
	local name = "Wanted"
	local color = color_config.wanted

	if not color then
		return name
	end

	if color:sub(1, 1) == "#" then
		vim.api.nvim_set_hl(0, name, { fg = color })
	else
		vim.api.nvim_set_hl(0, name, { link = color })
	end

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
	if package_config and package_config.color then
		return package_config.color
	end

	-- Fallback to default config
	return config_validator.DEFAULT_CONFIG.color
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
		-- Exclude "version" field (e.g., "version": "1.0.0")
		if package_name == "version" then
			return nil
		end
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

---@param package_config? PackageVersionConfig
---@return number timeout_seconds
M.get_timeout = function(package_config)
	if package_config and package_config.timeout then
		return package_config.timeout
	end

	return config_validator.DEFAULT_CONFIG.timeout
end

---@param job_id number The job ID returned by vim.fn.jobstart
---@param timeout_seconds number Timeout in seconds
---@param command_name string Name of the command for error messages
---@param on_timeout fun() Callback to execute on timeout (should reset guard flag and hide spinner)
---@return TimeoutTimer timer The timer object (must be stopped/closed in on_exit)
M.start_job_timeout = function(job_id, timeout_seconds, command_name, on_timeout)
	local logger = require("package-version.utils.logger")
	local timeout_timer = vim.uv.new_timer()

	timeout_timer:start(timeout_seconds * 1000, 0, function()
		vim.schedule(function()
			on_timeout()
			logger.error(string.format("%s timeout after %d seconds", command_name, timeout_seconds))
		end)

		pcall(vim.fn.jobstop, job_id)
	end)

	return timeout_timer
end

return M
