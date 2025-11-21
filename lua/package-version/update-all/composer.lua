local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")
local mutex = require("package-version.utils.mutex")
local cache = require("package-version.cache")
local window = require("package-version.utils.window")

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("Composer Update All") then
		return
	end

	local options = {
		{ label = "Latest", value = "" },
		{ label = "Patch", value = "--patch-only" },
	}

	window.display_select("Select Update Scope", options, function(update_scope)
		if not update_scope then
			mutex.unlock()
			return
		end

		logger.info("Updating all packages")

		local timeout_timer
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
				logger.error("Command 'composer update all' failed with code: " .. code)

				mutex.unlock()

				window.display_error(stderr_lines, "composer update")

				return
			end

			-- Display success output (composer writes to stderr)
			window.display_success(stderr_lines, "composer update")

			cache.invalidate_package_manager(cache.PACKAGE_MANAGER.COMPOSER)

			mutex.unlock()
		end

		local docker_config = common.get_docker_config(package_config)
		local cmd = "composer update --no-audit --no-progress --no-ansi"
		if update_scope ~= "" then
			cmd = cmd .. " " .. update_scope
		end
		local update_all_command = common.prepare_composer_command(cmd, docker_config, true)

		if not update_all_command then
			mutex.unlock()
			return
		end

		spinner.show(package_config.spinner)

		local job_id = vim.fn.jobstart(update_all_command, {
			stdout_buffered = true,
			on_stderr = function(_, data)
				if data then
					for _, line in ipairs(data) do
						if line and line ~= "" then
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
		timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "Composer update all command", function()
			mutex.unlock()

			spinner.hide()
		end)
	end)
end

return M
