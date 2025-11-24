local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")
local mutex = require("package-version.utils.mutex")
local cache = require("package-version.cache")
local window = require("package-version.utils.window")
local yarn_json = require("package-version.utils.parser.yarn-json")

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("Yarn Install") then
		return
	end

	logger.info("Installing packages from yarn.lock")

	local timeout_timer
	local stderr_lines = {}
	local stdout_lines = {}

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
		local formatted_lines = yarn_json.format_output(parsed, "yarn install")

		-- Check if there are errors in the JSON output OR non-zero exit code
		if code ~= 0 or #parsed.errors > 0 then
			logger.error("Command yarn install failed with code: " .. code)
			mutex.unlock()
			window.display_error(formatted_lines, "yarn install")
			return
		end

		window.display_success(formatted_lines, "yarn install")

		cache.invalidate_package_manager(cache.PACKAGE_MANAGER.YARN)

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)
	local install_command = common.prepare_yarn_command("yarn install --json", docker_config)

	if not install_command then
		mutex.unlock()
		return
	end

	spinner.show(package_config.spinner)

	local job_id = vim.fn.jobstart(install_command, {
		stderr_buffered = true,
		stdout_buffered = true,
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
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "Yarn install command", function()
		mutex.unlock()

		spinner.hide()
	end)
end

return M
