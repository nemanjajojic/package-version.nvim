local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")

local is_outdated_virtual_line_visible = false
local is_installed_virtual_line_visible = false

local is_installed_command_running = false
local is_outdated_command_running = false
local is_update_all_command_running = false
local is_update_single_command_running = false

---@param command string
---@param docker_config? DockerConfig
---@param ignore_platform boolean
---@return string|nil
local prepare_command = function(command, docker_config, ignore_platform)
	if docker_config then
		if not docker_config.composer_container_name or docker_config.composer_container_name == "" then
			logger.error(
				"Docker composer container name "
					.. docker_config.composer_container_name
					.. " is not specified in the configuration."
			)

			return nil
		end

		return "docker exec " .. docker_config.composer_container_name .. " " .. command
	end

	if ignore_platform then
		command = command .. " --ignore-platform-reqs"
	end

	return command
end

---@param package_config? PackageVersionConfig
M.installed = function(package_config)
	if is_installed_command_running then
		logger.warning("Composer installed command is already running.")

		return
	end

	local namespace_id = vim.api.nvim_create_namespace("Composer Installed")

	if is_installed_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		spinner.hide()

		is_installed_virtual_line_visible = false

		return
	end

	local color_config = common.get_default_color_config(package_config)

	local installed = {}

	local on_exit = function(job_id, code, event)
		if code ~= 0 then
			logger.error("Command 'composer show' failed with code: " .. code)

			spinner.hide()
			is_installed_command_running = false

			return
		end

		local json_str = table.concat(installed, "\n")

		local ok

		---@type table<{locked: table<{name: string, version: string}>}>
		local result

		ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		---@type table<string, {version: string}>
		local packages = {}

		for _, package_info in pairs(result.locked) do
			packages[package_info.name] = {
				version = package_info.version,
			}
		end

		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

		for line_number, line_content in ipairs(lines) do
			local package_name = common.get_package_name_from_line_json(line_content)
			local current_package = packages[package_name]

			if current_package ~= nil then
				common.set_virtual_text(line_number, current_package.version, namespace_id, "", color_config.current)
			end
		end

		spinner.hide()

		is_installed_virtual_line_visible = true
		is_installed_command_running = false
	end

	local docker_config = common.get_docker_config(package_config)

	local installed_command = prepare_command("composer show --locked --direct --format=json", docker_config, false)

	if not installed_command then
		return
	end

	spinner.show(package_config and package_config.spinner)

	is_installed_command_running = true

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
	if is_outdated_command_running then
		logger.warning("Composer outdated command is already running.")

		return
	end

	local namespace_id = vim.api.nvim_create_namespace("Composer Outdated")

	if is_outdated_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		spinner.hide()

		is_outdated_virtual_line_visible = false

		return
	end

	local color_config = common.get_default_color_config(package_config)

	local latest_hl = common.latest_hl()
	local wanted_hl = common.wanted_hl()
	local abandoned_hl = common.abandoned_hl()

	local outdated = {}

	local on_exit = function(job_id, code, event)
		if code ~= 0 then
			logger.error("Command 'composer outdated' failed with code: " .. code)

			spinner.hide()
			is_outdated_command_running = false

			return
		end

		local json_str = table.concat(outdated, "\n")

		local ok

		---@type table<{installed: table<{version: string, name: string, latest: string, ["latest-status"]: string, abandoned: boolean}>}>
		local result

		ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		---@type table<string, {version: string, latest: string, status: string, abandoned: boolean}>
		local packages = {}

		for _, package_info in pairs(result.installed) do
			packages[package_info.name] = {
				version = package_info.version,
				latest = package_info.latest,
				status = package_info["latest-status"],
				abandoned = package_info.abandoned,
			}
		end

		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

		for line_number, line_content in ipairs(lines) do
			local package_name = common.get_package_name_from_line_json(line_content)
			local current_package = packages[package_name]

			if current_package ~= nil then
				common.set_virtual_text(line_number, current_package.version, namespace_id, "", color_config.current)

				if current_package.status == "update-possible" then
					common.set_virtual_text(line_number, current_package.latest, namespace_id, " ", latest_hl)
				else
					common.set_virtual_text(line_number, current_package.latest, namespace_id, " ", wanted_hl)
				end

				if current_package.abandoned then
					common.set_virtual_text(line_number, "Abandoned", namespace_id, "  ", abandoned_hl)
				end
			end
		end

		spinner.hide()

		is_outdated_virtual_line_visible = true
		is_outdated_command_running = false
	end

	local docker_config = common.get_docker_config(package_config)
	local outdated_command = prepare_command("composer outdated --direct --format=json", docker_config, true)

	if not outdated_command then
		return
	end

	spinner.show(package_config and package_config.spinner)

	is_outdated_command_running = true

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

---@param package_config? PackageVersionConfig
M.update_all = function(package_config)
	if is_update_all_command_running then
		logger.warning("Composer update all command is already running.")

		return
	end

	logger.info("Updating all packages")

	is_update_all_command_running = true

	local on_exit = function(job_id, code, event)
		if code ~= 0 then
			logger.error("Command 'composer update all' failed with code: " .. code)

			spinner.hide()

			is_update_all_command_running = false

			return
		end

		spinner.hide("Composer packages updated successfully!")

		is_update_all_command_running = false
	end

	local docker_config = common.get_docker_config(package_config)
	local update_all_command =
		prepare_command("composer update --no-audit --no-progress --no-ansi", docker_config, true)

	if not update_all_command then
		return
	end

	spinner.show(package_config and package_config.spinner)

	vim.fn.jobstart(update_all_command, {
		stdout_buffered = false,
		on_exit = on_exit,
	})
end

---@param package_config? PackageVersionConfig
M.update_single = function(package_config)
	if is_update_single_command_running then
		logger.warning("Composer update single command is already running.")

		return
	end

	local is_package_up_to_date = false

	local current_line = vim.api.nvim_get_current_line()
	local package_name = common.get_package_name_from_line_json(current_line)

	if not package_name then
		logger.warning(
			"Could not determine package name from the current line. Make sure the cursor is on a valid package line."
		)

		return
	end

	logger.info("Updating package: " .. package_name)

	is_update_single_command_running = true

	local on_exit = function(job_id, code, event)
		if code ~= 0 then
			logger.error("Command composer update " .. package_name .. " failed with code: " .. code)

			spinner.hide()

			is_update_single_command_running = false

			return
		end

		if is_package_up_to_date then
			spinner.hide("Package " .. package_name .. " is already up to date!")
		else
			spinner.hide("Package " .. package_name .. " updated successfully!")
		end

		is_update_single_command_running = false
	end

	local docker_config = common.get_docker_config(package_config)
	local update_one_command =
		prepare_command("composer update " .. package_name .. " --no-audit --no-ansi", docker_config, true)

	if not update_one_command then
		return
	end

	spinner.show(package_config and package_config.spinner)

	vim.fn.jobstart(update_one_command, {
		stdout_buffered = true,
		on_stderr = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if string.find(line, "Nothing to install, update or remove") then
						is_package_up_to_date = true
					end
				end
			end
		end,
		on_exit = on_exit,
	})
end

return M
