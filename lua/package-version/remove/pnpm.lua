local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")
local mutex = require("package-version.utils.mutex")
local cache = require("package-version.cache")
local window = require("package-version.utils.window")

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("PNPM Remove") then
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
			window.display_error(stderr_lines, "pnpm remove " .. package_name)

			mutex.unlock()

			return
		end

		cache.invalidate_package_manager(cache.PACKAGE_MANAGER.PNPM)

		logger.info("Package " .. package_name .. " removed successfully!")

		-- Reload buffer to reflect changes in package.json
		vim.cmd("checktime")

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)
	local remove_command = common.prepare_pnpm_command("pnpm remove " .. package_name, docker_config)

	if not remove_command then
		return
	end

	spinner.show(package_config.spinner)

	local job_id = vim.fn.jobstart(remove_command, {
		stderr_buffered = true,
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
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "PNPM remove command", function()
		mutex.unlock()

		spinner.hide()
	end)
end

return M
