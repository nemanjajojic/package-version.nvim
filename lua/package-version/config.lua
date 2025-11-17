local M = {}

local VALID_SPINNER_TYPES = {
	pacman = true,
	ball = true,
	space = true,
	minimal = true,
	dino = true,
}

local DEFAULT_CONFIG = {
	color = {
		latest = "#a6e3a1",
		wanted = "#f9e2af",
		current = "Comment",
		abandoned = "#eba0ac",
	},
	spinner = {
		type = "space",
	},
	docker = nil,
	timeout = 60,
}

---@param color any
---@param field_name string
---@return boolean success
---@return string? error_message
local function validate_color(color, field_name)
	if type(color) ~= "string" then
		return false, string.format("%s must be a string, got %s", field_name, type(color))
	end

	-- Check if it's a hex color (3 or 6 digit)
	if color:match("^#%x%x%x%x%x%x$") or color:match("^#%x%x%x$") then
		return true
	end

	-- Check if it's a valid Neovim highlight group
	if vim.fn.hlexists(color) == 1 then
		return true
	end

	return false,
		string.format(
			"%s must be a valid hex color (#RRGGBB or #RGB) or existing highlight group, got '%s'",
			field_name,
			color
		)
end

---@param color_config any
---@return boolean success
---@return string? error_message
local function validate_color_config(color_config)
	if not color_config then
		return true
	end

	if type(color_config) ~= "table" then
		return false, "color config must be a table"
	end

	local valid_fields = { "latest", "wanted", "current", "abandoned" }

	for key, value in pairs(color_config) do
		if not vim.tbl_contains(valid_fields, key) then
			return false,
				string.format("Unknown color field: '%s'. Valid fields are: %s", key, table.concat(valid_fields, ", "))
		end

		local ok, err = validate_color(value, "color." .. key)
		if not ok then
			return false, err
		end
	end

	return true
end

--- Validate spinner configuration
---@param spinner_config any
---@return boolean success
---@return string? error_message
local function validate_spinner_config(spinner_config)
	if not spinner_config then
		return true
	end

	if type(spinner_config) ~= "table" then
		return false, "spinner config must be a table"
	end

	local allowed_fields = { type = true }
	for key in pairs(spinner_config) do
		if not allowed_fields[key] then
			return false, string.format("spinner.%s is not configurable. Only spinner.type can be set by users.", key)
		end
	end

	if spinner_config.type then
		if type(spinner_config.type) ~= "string" then
			return false, "spinner.type must be a string"
		end

		if not VALID_SPINNER_TYPES[spinner_config.type] then
			local valid = vim.tbl_keys(VALID_SPINNER_TYPES)
			table.sort(valid)
			return false,
				string.format(
					"spinner.type must be one of: %s (got '%s')",
					table.concat(valid, ", "),
					spinner_config.type
				)
		end
	end

	return true
end

---@param docker_config any
---@return boolean success
---@return string? error_message
local function validate_docker_config(docker_config)
	if not docker_config then
		return true
	end

	if type(docker_config) ~= "table" then
		return false, "docker config must be a table"
	end

	local valid_container_names = {
		"composer_container_name",
		"npm_container_name",
		"yarn_container_name",
		"pnpm_container_name",
	}

	for key, value in pairs(docker_config) do
		if not vim.tbl_contains(valid_container_names, key) then
			return false,
				string.format(
					"Unknown docker field: '%s'. Valid fields are: %s",
					key,
					table.concat(valid_container_names, ", ")
				)
		end

		if type(value) ~= "string" then
			return false, string.format("docker.%s must be a string, got %s", key, type(value))
		end

		if value == "" then
			return false, string.format("docker.%s cannot be empty", key)
		end
	end

	return true
end

---@param timeout any
---@return boolean success
---@return string? error_message
local function validate_timeout(timeout)
	if not timeout then
		return true
	end

	if type(timeout) ~= "number" then
		return false, "timeout must be a number"
	end

	if timeout <= 0 then
		return false, "timeout must be greater than 0"
	end

	if timeout > 300 then
		return false, "timeout must be less than or equal to 300 seconds (5 minutes)"
	end

	return true
end

---@param config? PackageVersionConfig
---@return true, PackageVersionConfig
---@overload fun(config?: PackageVersionConfig): false, string
function M.validate(config)
	if config == nil then
		return true, DEFAULT_CONFIG
	end

	if type(config) ~= "table" then
		return false, "Configuration must be a table"
	end

	local ok, err = validate_color_config(config.color)
	if not ok then
		return false, "Invalid color config: " .. err
	end

	ok, err = validate_spinner_config(config.spinner)
	if not ok then
		return false, "Invalid spinner config: " .. err
	end

	ok, err = validate_docker_config(config.docker)
	if not ok then
		return false, "Invalid docker config: " .. err
	end

	ok, err = validate_timeout(config.timeout)
	if not ok then
		return false, "Invalid timeout config: " .. err
	end

	local valid_top_level = { "color", "spinner", "docker", "timeout" }
	for key in pairs(config) do
		if not vim.tbl_contains(valid_top_level, key) then
			return false,
				string.format(
					"Unknown configuration key: '%s'. Valid keys are: %s",
					key,
					table.concat(valid_top_level, ", ")
				)
		end
	end

	local merged = vim.tbl_deep_extend("force", DEFAULT_CONFIG, config)

	return true, merged
end

M.DEFAULT_CONFIG = DEFAULT_CONFIG

return M
