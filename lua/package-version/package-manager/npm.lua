local M = {}

local spinner = require("package-version.utils.spinner")
local logger = require("package-version.utils.logger")
local common = require("package-version.utils.common")

local is_npm_outdated_virtual_line_visible = false
local is_npm_installed_virtual_line_visible = false

---@param command string
---@param docker_config? DockerConfig
---@return string|nil
local prepare_command = function(command, docker_config)
	if docker_config then
		if not docker_config.npm_container_name or docker_config.npm_container_name == "" then
			logger.error(
				"Docker NodeJs container name "
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

	if is_npm_installed_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		is_npm_installed_virtual_line_visible = false

		spinner.hide()

		return
	end

	local color_config = common.get_default_color_config(package_config)

	local installed = {}

	local on_exit = function(job_id, code, event)
		if code ~= 0 then
			logger.error("Command NPM installed' failed with code: " .. code)

			return
		end

		local json_str = table.concat(installed, "\n")
		local ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		for package_name, package_info in pairs(result.dependencies) do
			local line_number = common.get_current_line_number(package_name)

			if line_number then
				common.set_virtual_text(line_number, package_info.version, namespace_id, "  ", color_config.current)
			end
		end

		is_npm_installed_virtual_line_visible = true

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

	if is_npm_outdated_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		is_npm_outdated_virtual_line_visible = false

		spinner.hide()

		return
	end

	local color_config = common.get_default_color_config(package_config)

	local major_hl = common.major_hl()
	local minor_hl = common.minor_hl()

	local outdated = {}

	local on_exit = function(job_id, code, event)
		-- if code ~= 0 then
		-- 	logger.error("Command NPM outdated' failed with code: " .. code)
		--
		-- 	return
		-- end

		local json_str = table.concat(outdated, "\n")
		local ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		for package_name, package_info in pairs(result) do
			local line_number = common.get_current_line_number(package_name)
			common.set_virtual_text(line_number, package_info.current, namespace_id, "", color_config.current)

			if line_number then
				if package_info.current ~= package_info.wanted and package_info.wanted == package_info.latest then
					common.set_virtual_text(line_number, package_info.wanted, namespace_id, " ", minor_hl)

					goto continue
				end

				if package_info.current ~= package_info.wanted and package_info.wanted ~= package_info.latest then
					common.set_virtual_text(line_number, package_info.latest, namespace_id, " ", major_hl)
					common.set_virtual_text(line_number, package_info.wanted, namespace_id, " ", minor_hl)

					goto continue
				end

				if package_info.current == package_info.wanted and package_info.wanted ~= package_info.latest then
					common.set_virtual_text(line_number, package_info.latest, namespace_id, " ", major_hl)

					goto continue
				end

				::continue::
			end
		end

		is_npm_outdated_virtual_line_visible = true

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
