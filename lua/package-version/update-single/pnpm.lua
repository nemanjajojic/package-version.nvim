local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")
local mutex = require("package-version.utils.mutex")
local cache = require("package-version.cache")
local window = require("package-version.utils.window")
local pnpm_json = require("package-version.utils.parser.pnpm-json")

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("PNPM Update Single") then
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

		-- Combine stdout and stderr for parsing
		local all_lines = {}
		for _, line in ipairs(stdout_lines) do
			table.insert(all_lines, line)
		end
		for _, line in ipairs(stderr_lines) do
			table.insert(all_lines, line)
		end

		-- Parse NDJSON output
		local parsed = pnpm_json.parse_ndjson(all_lines)

		-- Check for errors
		if code ~= 0 or #parsed.errors > 0 then
			logger.error("Command pnpm update " .. package_name .. " failed with code: " .. code)
			mutex.unlock()
			local error_lines = pnpm_json.format_output(parsed, "pnpm update " .. package_name)
			window.display_error(error_lines, "pnpm update " .. package_name)
			return
		end

		cache.invalidate_package_manager(cache.PACKAGE_MANAGER.PNPM)

		local success_lines = pnpm_json.format_output(parsed, "pnpm update " .. package_name)
		window.display_success(success_lines, "pnpm update " .. package_name)

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)
	local update_one_command = common.prepare_pnpm_command("pnpm update " .. package_name .. " --reporter ndjson", docker_config)

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
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "PNPM update single command", function()
		mutex.unlock()

		spinner.hide()
	end)
end

return M
