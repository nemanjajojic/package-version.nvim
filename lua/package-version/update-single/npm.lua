local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")
local mutex = require("package-version.utils.mutex")
local cache = require("package-version.cache")
local window = require("package-version.utils.window")

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("NPM Update Single") then
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

	local command_output = {}
	local stderr_lines = {}

	local timeout_timer

	local on_exit = function(job_id, code, event)
		local ok, err = pcall(function()
			timeout_timer:stop()
			timeout_timer:close()
		end)

		if not ok then
			logger.error("Failed to cleanup timeout timer: " .. tostring(err))
		end

		spinner.hide()

		if code ~= 0 then
			logger.error("Command npm update " .. package_name .. " failed with code: " .. code)

			mutex.unlock()

			window.display_error(stderr_lines, "npm update " .. package_name)

			return
		end

		cache.invalidate_package_manager(cache.PACKAGE_MANAGER.NPM)

		window.display_success(command_output, "npm update " .. package_name)

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)
	local update_one_command =
		common.prepare_npm_command("npm update " .. package_name .. " --no-fund --no-audit --json", docker_config)

	if not update_one_command then
		return
	end

	spinner.show(package_config.spinner)

	local job_id = vim.fn.jobstart(update_one_command, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(command_output, line)
					end
				end
			end
		end,
		on_stderr = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(stderr_lines, line)
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
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "NPM update single command", function()
		mutex.unlock()

		spinner.hide()
	end)
end

return M
