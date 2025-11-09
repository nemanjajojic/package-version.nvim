local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")

local is_outdated_virtual_line_visible = false
local is_installed_virtual_line_visible = false

---@param command string
---@param docker_config? DockerConfig
---@return string|nil
local prepare_command = function(command, docker_config)
	if docker_config then
		if not docker_config.composer_container_name or docker_config.composer_container_name == "" then
			logger.error(
				"Docker PHP container name "
					.. docker_config.composer_container_name
					.. " is not specified in the configuration."
			)

			return nil
		end

		return "docker exec " .. docker_config.composer_container_name .. " " .. command
	end

	return command
end

---@param package_config? PackageVersionConfig
M.installed = function(package_config)
	local namespace_id = vim.api.nvim_create_namespace("Composer Installed")

	if is_installed_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		is_installed_virtual_line_visible = false

		spinner.hide()

		return
	end

	local color_config = common.get_default_color_config(package_config)

	local abandoned_hl = common.abandoned_hl()

	local installed = {}

	local on_exit = function(job_id, code, event)
		if code ~= 0 then
			logger.error("Command 'composer outdated' failed with code: " .. code)

			return
		end

		local json_str = table.concat(installed, "\n")
		local ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		for _, package_info in pairs(result.locked) do
			local line_number = common.get_current_line_number(package_info.name)

			if line_number then
				common.set_virtual_text(line_number, package_info.version, namespace_id, "", color_config.current)

				if package_info.abandoned then
					common.set_virtual_text(line_number, "Abandoned", namespace_id, "  ", abandoned_hl)
				end
			end
		end

		is_installed_virtual_line_visible = true

		spinner.hide()
	end

	local docker_config = common.get_docker_config(package_config)

	local installed_command = prepare_command("composer show --locked --direct --format=json", docker_config)

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
M.outated = function(package_config)
	local namespace_id = vim.api.nvim_create_namespace("Composer Outdated")

	if is_outdated_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		is_outdated_virtual_line_visible = false

		spinner.hide()

		return
	end

	local color_config = common.get_default_color_config(package_config)

	local major_hl = common.major_hl()
	local minor_hl = common.minor_hl()
	local up_to_date_hl = common.up_to_date_hl()

	local outdated = {}

	local on_exit = function(job_id, code, event)
		if code ~= 0 then
			logger.error("Command 'composer outdated' failed with code: " .. code)

			return
		end

		local json_str = table.concat(outdated, "\n")
		local ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		for _, package_info in pairs(result.installed) do
			local line_number = common.get_current_line_number(package_info.name)

			if line_number then
				common.set_virtual_text(line_number, package_info.version, namespace_id, "", color_config.current)

				if package_info["latest-status"] == "update-possible" then
					common.set_virtual_text(line_number, package_info.latest, namespace_id, " ", major_hl)
				elseif package_info["latest-status"] == "up-to-date" then
					common.set_virtual_text(line_number, "", namespace_id, " ", up_to_date_hl)
				else
					common.set_virtual_text(line_number, package_info.latest, namespace_id, " ", minor_hl)
				end
			end
		end

		is_outdated_virtual_line_visible = true

		spinner.hide()
	end

	local docker_config = common.get_docker_config(package_config)
	local outdated_command =
		prepare_command("composer outdated --direct --format=json --ignore-platform-reqs", docker_config)

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
