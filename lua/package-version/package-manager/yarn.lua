local M = {}

local spinner = require("package-version.utils.spinner")
local logger = require("package-version.utils.logger")
local common = require("package-version.utils.common")

local is_yarn_outdated_virtual_line_visible = false
local is_yarn_installed_virtual_line_visible = false

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
	local namespace_id = vim.api.nvim_create_namespace("Yarn Installed")

	if is_yarn_installed_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		is_yarn_installed_virtual_line_visible = false

		spinner.hide()

		return
	end

	local color_config = common.get_default_color_config(package_config)

	local installed = {}

	local on_exit = function(job_id, code, event)
		if code ~= 0 then
			logger.error("Command Yarn installed' failed with code: " .. code)

			return
		end

		local json_str = table.concat(installed, "\n")
		local ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		for _, package_info in ipairs(result.data.trees) do
			local name, version = package_info.name:match("([^@]+)@(.+)")

			local line_number = common.get_current_line_number(name)

			if line_number then
				common.set_virtual_text(line_number, version, namespace_id, "  ", color_config.current)
			end
		end

		is_yarn_installed_virtual_line_visible = true

		spinner.hide()
	end

	local docker_config = common.get_docker_config(package_config)

	local installed_command = prepare_command("yarn list --depth=0 --json", docker_config)

	if not installed_command then
		return
	end

	spinner.show(package_config and package_config.spinner)

	vim.fn.jobstart(installed_command, {
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
end

---@param package_config? PackageVersionConfig
M.outdated = function(package_config)
	local namespace_id = vim.api.nvim_create_namespace("Yarn Outdated")

	if is_yarn_outdated_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		is_yarn_outdated_virtual_line_visible = false

		spinner.hide()

		return
	end

	local color_config = common.get_default_color_config(package_config)

	local major_hl = common.major_hl()
	local minor_hl = common.minor_hl()

	local outdated = {}

	local on_exit = function(job_id, code, event)
		-- if code ~= 0 then
		-- 	logger.error("Command Yarn outdated' failed with code: " .. code)
		--
		-- 	return
		-- end

		local json_str = table.concat(outdated, "\n")
		local ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		for _, package_info in ipairs(result.data.body) do
			local package_name = package_info[1]
			local current = package_info[2]
			local wanted = package_info[3]
			local latest = package_info[4]

			local line_number = common.get_current_line_number(package_name)

			common.set_virtual_text(line_number, current, namespace_id, "", color_config.current)

			if line_number then
				if current ~= wanted and wanted == latest then
					common.set_virtual_text(line_number, wanted, namespace_id, " ", minor_hl)

					goto continue
				end

				if current ~= wanted and wanted ~= latest then
					common.set_virtual_text(line_number, latest, namespace_id, " ", major_hl)
					common.set_virtual_text(line_number, wanted, namespace_id, " ", minor_hl)

					goto continue
				end

				if current == wanted and wanted ~= latest then
					common.set_virtual_text(line_number, latest, namespace_id, " ", major_hl)

					goto continue
				end

				::continue::
			end
		end

		is_yarn_outdated_virtual_line_visible = true

		spinner.hide()
	end

	local docker_config = common.get_docker_config(package_config)

	local outdated_command = prepare_command("yarn outdated --json", docker_config)

	if not outdated_command then
		return
	end

	spinner.show(package_config and package_config.spinner)

	vim.fn.jobstart(outdated_command, {
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
end

return M
