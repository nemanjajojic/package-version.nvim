local M = {}

local spinner = require("package-version.utils.spinner")
local logger = require("package-version.utils.logger")
local common = require("package-version.utils.common")

local is_outdated_virtual_line_visible = false
local is_installed_virtual_line_visible = false

---@param command string
---@param docker_config? DockerConfig
---@return string|nil
local prepare_command = function(command, docker_config)
	if docker_config then
		if not docker_config.npm_container_name or docker_config.npm_container_name == "" then
			logger.error(
				"Docker npm container name "
					.. docker_config.npm_container_name
					.. " is not specified in the configuration."
			)

			return nil
		end

		return "docker exec " .. docker_config.npm_container_name .. " " .. command
	end

	return command
end

---@param package_config? PackageVersionConfig
M.installed = function(package_config)
	local namespace_id = vim.api.nvim_create_namespace("NPM Installed")

	if is_installed_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		is_installed_virtual_line_visible = false

		spinner.hide()

		return
	end

	local color_config = common.get_default_color_config(package_config)

	local installed = {}

	local on_exit = function(code)
		-- if code ~= 0 then
		-- 	logger.error("Command NPM installed' failed with code: " .. code)
		--
		-- 	return
		-- end

		local json_str = table.concat(installed, "\n")

		local ok

		---@type table<{dependencies: table<string, {version: string}>, devDependencies: table<string, {version: string}>}>
		local result

		ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

		for line_number, line_content in ipairs(lines) do
			local package_name = common.get_package_name_from_line(line_content)
			local current_package = result.dependencies[package_name]

			if current_package ~= nil then
				common.set_virtual_text(line_number, current_package.version, namespace_id, "", color_config.current)
			end
		end

		is_installed_virtual_line_visible = true

		spinner.hide()
	end

	local docker_config = common.get_docker_config(package_config)

	local installed_command = prepare_command("npm list --depth=0 --package-lock-only --json", docker_config)

	if not installed_command then
		return
	end

	spinner.show(package_config and package_config.spinner)

	vim.fn.jobstart(installed_command, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(installed, line)
					end
				end
			end
		end,
		on_exit = on_exit,
	})
end

---@param package_config? PackageVersionConfig
M.outdated = function(package_config)
	local namespace_id = vim.api.nvim_create_namespace("NPM Outdated")

	if is_outdated_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		is_outdated_virtual_line_visible = false

		spinner.hide()

		return
	end

	local color_config = common.get_default_color_config(package_config)

	local latest_hl = common.latest_hl()
	local wanted_hl = common.wanted_hl()

	local outdated = {}

	local on_exit = function()
		local json_str = table.concat(outdated, "\n")

		local ok

		---@type table<string, {current: string, wanted: string, latest: string}>
		local result

		ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

		for line_number, line_content in ipairs(lines) do
			local package_name = common.get_package_name_from_line(line_content)
			local current_package = result[package_name]

			if current_package ~= nil then
				common.set_virtual_text(line_number, current_package.current, namespace_id, "", color_config.current)

				if
					current_package.current ~= current_package.wanted
					and current_package.wanted == current_package.latest
				then
					common.set_virtual_text(line_number, current_package.wanted, namespace_id, " ", wanted_hl)

					goto continue
				end

				if
					current_package.current ~= current_package.wanted
					and current_package.wanted ~= current_package.latest
				then
					common.set_virtual_text(line_number, current_package.latest, namespace_id, " ", latest_hl)
					common.set_virtual_text(line_number, current_package.wanted, namespace_id, " ", wanted_hl)

					goto continue
				end

				if
					current_package.current == current_package.wanted
					and current_package.wanted ~= current_package.latest
				then
					common.set_virtual_text(line_number, current_package.latest, namespace_id, " ", latest_hl)

					goto continue
				end

				::continue::
			end
		end

		is_outdated_virtual_line_visible = true

		spinner.hide()
	end

	local docker_config = common.get_docker_config(package_config)

	local outdated_command = prepare_command("npm outdated --json", docker_config)

	if not outdated_command then
		return
	end

	spinner.show(package_config and package_config.spinner)

	vim.fn.jobstart(outdated_command, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(outdated, line)
					end
				end
			end
		end,
		on_exit = on_exit,
	})
end

return M
