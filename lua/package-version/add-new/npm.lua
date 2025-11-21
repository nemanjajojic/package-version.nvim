local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")
local mutex = require("package-version.utils.mutex")
local cache = require("package-version.cache")
local window = require("package-version.utils.window")

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("NPM Add New") then
		return
	end

	local options = {
		{ label = "Production", value = "" },
		{ label = "Development (--save-dev)", value = "--save-dev" },
	}

	window.display_select("Select Dependency Type", options, function(dep_type)
		if dep_type == nil then
			mutex.unlock()
			return
		end

		window.display_input("Package Name", function(package_name)
			if not package_name then
				mutex.unlock()
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
					window.display_error(stderr_lines, "npm install " .. package_name)
					mutex.unlock()
					return
				end

				cache.invalidate_package_manager(cache.PACKAGE_MANAGER.NPM)

				vim.cmd("checktime")

				mutex.unlock()
			end

			-- Build command with dependency type flag
			local cmd = "npm install " .. package_name
			if dep_type ~= "" then
				cmd = cmd .. " " .. dep_type
			end
			cmd = cmd .. " --color=always"

			local docker_config = common.get_docker_config(package_config)
			local install_command = common.prepare_npm_command(cmd, docker_config)

			if not install_command then
				mutex.unlock()
				return
			end

			spinner.show(package_config.spinner)

			local job_id = vim.fn.jobstart(install_command, {
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
			timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "NPM add new command", function()
				mutex.unlock()
				spinner.hide()
			end)
		end)
	end)
end

return M
