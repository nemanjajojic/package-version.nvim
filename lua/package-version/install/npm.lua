local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")
local mutex = require("package-version.utils.mutex")
local cache = require("package-version.cache")
local window = require("package-version.utils.window")

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("NPM Install") then
		return
	end

	logger.info("Installing packages from package-lock.json")

	local timeout_timer
	local output_lines = {}
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

		if code ~= 0 then
			logger.error("Command npm install failed with code: " .. code)

			mutex.unlock()

			window.display_error(stderr_lines, "npm install")

			return
		end

		-- Display success output
		window.display_success(output_lines, "npm install")

		cache.invalidate_package_manager(cache.PACKAGE_MANAGER.NPM)

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)
	local install_command = common.prepare_npm_command("npm install --no-audit --no-fund", docker_config)

	if not install_command then
		mutex.unlock()
		return
	end

	spinner.show(package_config.spinner)

	local job_id = vim.fn.jobstart(install_command, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(output_lines, line)
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
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "NPM install command", function()
		mutex.unlock()

		spinner.hide()
	end)
end

return M
