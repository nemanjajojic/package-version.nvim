local M = {}

local spinner = require("package-version.utils.spinner")
local logger = require("package-version.utils.logger")
local common = require("package-version.utils.common")

local is_outdated_virtual_line_visible = false
local is_installed_virtual_line_visible = false

local is_installed_command_running = false
local is_outdated_command_running = false
local is_update_all_command_running = false
local is_update_single_command_running = false

---@param command string
---@param docker_config? DockerConfig
---@return string|nil
local prepare_command = function(command, docker_config)
	if docker_config then
		if not docker_config.yarn_container_name or docker_config.yarn_container_name == "" then
			logger.error(
				"Docker yarn container name "
					.. docker_config.yarn_container_name
					.. " is not specified in the configuration."
			)

			return nil
		end

		return "docker exec " .. docker_config.yarn_container_name .. " " .. command
	end

	return command
end

---@param package_config? PackageVersionConfig
M.installed = function(package_config)
	if is_installed_command_running then
		logger.warning("Yarn installed command is already running.")

		return
	end

	local namespace_id = vim.api.nvim_create_namespace("Yarn Installed")

	if is_installed_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		spinner.hide()

		is_installed_virtual_line_visible = false

		return
	end

	local color_config = common.get_default_color_config(package_config)

	local installed = {}

	local timeout_timer

	local on_exit = function(job_id, code, event)
		local ok, err = pcall(function()
			timeout_timer:stop()
			timeout_timer:close()
		end)

		if not ok then
			logger.error("Failed to cleanup timeout timer: " .. tostring(err))
		end

		if code ~= 0 then
			logger.error("Command 'yarn list' failed with code: " .. code)

			spinner.hide()
			is_installed_command_running = false

			return
		end

		local json_str = table.concat(installed, "\n")

		---@type table<{data: {trees: table<{name: string}>}}>
		local result

		ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		---@type table<string, {version: string}>
		local packages = {}

		for _, package_info in pairs(result.data.trees) do
			local name, version = package_info.name:match("^(.-)@(.+)$")

			packages[name] = {
				version = version,
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

	local installed_command = prepare_command("yarn list --depth=0 --json", docker_config)

	if not installed_command then
		return
	end

	spinner.show(package_config and package_config.spinner)

	is_installed_command_running = true

	local job_id = vim.fn.jobstart(installed_command, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" and line:find('"type":"tree"') then
						table.insert(installed, line)
					end
				end
			end
		end,
		on_exit = on_exit,
	})

	if job_id <= 0 then
		is_installed_command_running = false
		spinner.hide()
		logger.error("Failed to start job")
		return
	end

	local timeout_seconds = common.get_timeout(package_config)
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "Yarn installed command", function()
		is_installed_command_running = false
		spinner.hide()
	end)
end

---@param package_config? PackageVersionConfig
M.outdated = function(package_config)
	if is_outdated_command_running then
		logger.warning("Yarn outdated command is already running.")

		return
	end

	local namespace_id = vim.api.nvim_create_namespace("Yarn Outdated")

	if is_outdated_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		spinner.hide()

		is_outdated_virtual_line_visible = false

		return
	end

	local color_config = common.get_default_color_config(package_config)

	local latest_hl = common.latest_hl(color_config)
	local wanted_hl = common.wanted_hl(color_config)

	local outdated = {}

	local timeout_timer

	local on_exit = function(job_id, code, event)
		local ok, err = pcall(function()
			timeout_timer:stop()
			timeout_timer:close()
		end)

		if not ok then
			logger.error("Failed to cleanup timeout timer: " .. tostring(err))
		end

		if code == 0 then
			spinner.hide("No outdated packages!")
			is_outdated_command_running = false
			return
		end

		-- yarn outdated returns exit code 1 when outdated packages exist, which is expected
		if code ~= 0 and code ~= 1 then
			logger.error("Command 'yarn outdated' failed with code: " .. code)

			spinner.hide()
			is_outdated_command_running = false

			return
		end

		local json_str = table.concat(outdated, "\n")

		---@type table<{data: { body: { [1]: string, [2]: string, [3]: string, [4]: string }[]}}>
		local result

		ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		---@type table<string, {current: string, wanted: string, latest: string}>
		local packages = {}

		for _, package_info in ipairs(result.data.body) do
			packages[package_info[1]] = {
				current = package_info[2],
				wanted = package_info[3],
				latest = package_info[4],
			}
		end

		local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

		for line_number, line_content in ipairs(lines) do
			local package_name = common.get_package_name_from_line_json(line_content)
			local current_package = packages[package_name]

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

		spinner.hide()

		is_outdated_virtual_line_visible = true
		is_outdated_command_running = false
	end

	local docker_config = common.get_docker_config(package_config)

	local outdated_command = prepare_command("yarn outdated --json", docker_config)

	if not outdated_command then
		return
	end

	spinner.show(package_config and package_config.spinner)

	is_outdated_command_running = true

	local job_id = vim.fn.jobstart(outdated_command, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" and line:find('"type":"table"') then
						table.insert(outdated, line)
					end
				end
			end
		end,
		on_exit = on_exit,
	})

	if job_id <= 0 then
		is_outdated_command_running = false
		spinner.hide()
		logger.error("Failed to start job")
		return
	end

	local timeout_seconds = common.get_timeout(package_config)
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "Yarn outdated command", function()
		is_outdated_command_running = false
		spinner.hide()
	end)
end

---@param package_config? PackageVersionConfig
M.update_all = function(package_config)
	if is_update_all_command_running then
		logger.warning("Yarn update all command is already running.")

		return
	end

	logger.info("Updating all packages")

	is_update_all_command_running = true

	local timeout_timer

	local on_exit = function(job_id, code, event)
		local ok, err = pcall(function()
			timeout_timer:stop()
			timeout_timer:close()
		end)

		if not ok then
			logger.error("Failed to cleanup timeout timer: " .. tostring(err))
		end

		if code ~= 0 then
			logger.error("Yarn update all failed with code: " .. code)

			spinner.hide()

			is_update_all_command_running = false

			return
		end

		spinner.hide("Yarn packages updated successfully!")

		is_update_all_command_running = false
	end

	local docker_config = common.get_docker_config(package_config)
	local update_all_command = prepare_command("yarn upgrade --no-audit --silent", docker_config)

	if not update_all_command then
		return
	end

	spinner.show(package_config and package_config.spinner)

	local job_id = vim.fn.jobstart(update_all_command, {
		stdout_buffered = false,
		on_exit = on_exit,
	})

	if job_id <= 0 then
		is_update_all_command_running = false
		spinner.hide()
		logger.error("Failed to start job")
		return
	end

	local timeout_seconds = common.get_timeout(package_config)
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "Yarn update all command", function()
		is_update_all_command_running = false
		spinner.hide()
	end)
end

---@param package_config? PackageVersionConfig
M.update_single = function(package_config)
	if is_update_single_command_running then
		logger.warning("Yarn update single command is already running.")

		return
	end

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

	local timeout_timer

	local on_exit = function(job_id, code, event)
		local ok, err = pcall(function()
			timeout_timer:stop()
			timeout_timer:close()
		end)

		if not ok then
			logger.error("Failed to cleanup timeout timer: " .. tostring(err))
		end

		if code ~= 0 then
			logger.error("Command yarn upgrade " .. package_name .. " failed with code: " .. code)

			spinner.hide()

			is_update_single_command_running = false

			return
		end

		spinner.hide("Package " .. package_name .. " updated successfully!")

		is_update_single_command_running = false
	end

	local docker_config = common.get_docker_config(package_config)
	local update_one_command = prepare_command("yarn upgrade " .. package_name .. " --silent", docker_config)

	if not update_one_command then
		return
	end

	spinner.show(package_config and package_config.spinner)

	local job_id = vim.fn.jobstart(update_one_command, {
		stdout_buffered = false,
		on_exit = on_exit,
	})

	if job_id <= 0 then
		is_update_single_command_running = false
		spinner.hide()
		logger.error("Failed to start job")
		return
	end

	local timeout_seconds = common.get_timeout(package_config)
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "Yarn update single command", function()
		is_update_single_command_running = false
		spinner.hide()
	end)
end

return M
