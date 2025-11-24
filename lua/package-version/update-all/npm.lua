local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")
local mutex = require("package-version.utils.mutex")
local cache = require("package-version.cache")
local window = require("package-version.utils.window")
local npm_json = require("package-version.utils.parser.npm-json")

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("NPM Update All") then
		return
	end

	logger.info("Updating all packages")

	local timeout_timer
	local stdout_lines = {}
	local stderr_lines = {}

	local on_exit = function(job_id, code, event)
		local ok, err = pcall(function()
			timeout_timer:stop()
			timeout_timer:close()
		end)

		if not ok then
			logger.error("Failed to cleanup timeout timer: " .. tostring(err))
		end

		spinner.hide()

		local parsed = npm_json.parse_json(stdout_lines)

		if code ~= 0 or not parsed.success then
			logger.error("Command npm update failed with code: " .. code)
			mutex.unlock()

			local error_lines
			if not parsed.success then
				error_lines = npm_json.format_output(parsed, "npm update")
			else
				error_lines = stderr_lines
			end

			window.display_error(error_lines, "npm update")
			return
		end

		local success_lines = npm_json.format_output(parsed, "npm update")
		window.display_success(success_lines, "npm update")

		cache.invalidate_package_manager(cache.PACKAGE_MANAGER.NPM)

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)
	local update_all_command = common.prepare_npm_command("npm update --json", docker_config)

	if not update_all_command then
		return
	end

	spinner.show(package_config.spinner)

	local job_id = vim.fn.jobstart(update_all_command, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(stdout_lines, line)
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
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "NPM update all command", function()
		mutex.unlock()

		spinner.hide()
	end)
end

return M
