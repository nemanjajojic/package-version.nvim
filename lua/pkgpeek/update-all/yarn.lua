local M = {}

local logger = require("pkgpeek.utils.logger")
local spinner = require("pkgpeek.utils.spinner")
local common = require("pkgpeek.utils.common")
local mutex = require("pkgpeek.utils.mutex")
local cache = require("pkgpeek.cache")
local window = require("pkgpeek.utils.window")
local yarn_json = require("pkgpeek.utils.parser.yarn-json")

---@param package_config PkgPeekValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("Yarn Update All") then
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

		-- Combine stdout and stderr for parsing (yarn sends JSON to both)
		local all_lines = {}
		for _, line in ipairs(stdout_lines) do
			table.insert(all_lines, line)
		end
		for _, line in ipairs(stderr_lines) do
			table.insert(all_lines, line)
		end

		-- Parse JSON output from both streams
		local parsed = yarn_json.parse_jsonl(all_lines)
		local formatted_lines = yarn_json.format_output(parsed, "yarn upgrade")

		-- Check if there are errors in the JSON output OR non-zero exit code
		if code ~= 0 or #parsed.errors > 0 then
			logger.error("Yarn update all failed with code: " .. code)
			mutex.unlock()
			window.display_error(formatted_lines, "yarn upgrade")
			return
		end

		window.display_success(formatted_lines, "yarn upgrade")

		cache.invalidate_package_manager(cache.PACKAGE_MANAGER.YARN)

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)
	local update_all_command = common.prepare_yarn_command("yarn upgrade --json", docker_config)

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
					if line and line ~= "" then
						table.insert(stdout_lines, line)
					end
				end
			end
		end,
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
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "Yarn update all command", function()
		mutex.unlock()

		spinner.hide()
	end)
end

return M
