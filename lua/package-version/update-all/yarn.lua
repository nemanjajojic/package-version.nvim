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

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("Yarn Update All") then
		return
	end

	logger.info("Updating all packages")

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

			mutex.unlock()

			return
		end

		cache.invalidate_package_manager(cache.PACKAGE_MANAGER.YARN)

		spinner.hide("Yarn packages updated successfully!")

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)
	local update_all_command = prepare_command("yarn upgrade --no-audit --silent", docker_config)

	if not update_all_command then
		return
	end

	spinner.show(package_config.spinner)

	local job_id = vim.fn.jobstart(update_all_command, {
		stdout_buffered = false,
		on_exit = on_exit,
	})

	if job_id <= 0 then
		mutex.unlock()

		spinner.hide()

		logger.error("Failed to start job")

		return
	end

	local timeout_seconds = common.get_timeout(package_config)
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "Yarn update all command", function()
		mutex.unlock()

		spinner.hide()
	end)
end

return M
