local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")
local mutex = require("package-version.utils.mutex")
local cache = require("package-version.cache")
---@param command string
---@param docker_config? DockerValidatedConfig
---@return string|nil
local prepare_command = function(command, docker_config)
	if docker_config then
		if not docker_config.pnpm_container_name or docker_config.pnpm_container_name == "" then
			logger.error(
				"Docker pnpm container name "
					.. docker_config.pnpm_container_name
					.. " is not specified in the configuration."
			)

			return nil
		end

		return "docker exec " .. docker_config.pnpm_container_name .. " " .. command
	end

	return command
end

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("PNPM Update Single") then
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
			logger.error("Command pnpm update " .. package_name .. " failed with code: " .. code)

			spinner.hide()

			mutex.unlock()

			return
		end

		cache.invalidate_package_manager(cache.PACKAGE_MANAGER.PNPM)

		if is_package_up_to_date then
			spinner.hide("Package " .. package_name .. " is already up to date!")
		else
			spinner.hide("Package " .. package_name .. " updated successfully!")
		end

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)
	local update_one_command = prepare_command("pnpm update " .. package_name, docker_config)

	if not update_one_command then
		return
	end

	spinner.show(package_config.spinner)

	local job_id = vim.fn.jobstart(update_one_command, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line:match("Already up to date") then
						is_package_up_to_date = true
					end
				end
			end
		end,

		on_exit = on_exit,
	})

	if job_id <= 0 then
		mutex.unlock()

		spinner.hide()

		logger.error("Failed to start job")

		return
	end

	local timeout_seconds = common.get_timeout(package_config)
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "PNPM update single command", function()
		mutex.unlock()

		spinner.hide()
	end)
end

return M
