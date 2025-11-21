local M = {}

local logger = require("package-version.utils.logger")
local common = require("package-version.utils.common")
local homepage_common = require("package-version.homepage.common")
local mutex = require("package-version.utils.mutex")


---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("PNPM Homepage") then
		return
	end

	local current_line = vim.api.nvim_get_current_line()
	local package_name = common.get_package_name_from_line_json(current_line)

	if not package_name then
		logger.warning(
			"Could not determine package name from the current line. Make sure the cursor is on a valid package line."
		)

		mutex.unlock()
		return
	end

	local homepage_output = {}
	local timeout_timer

	local on_exit = function(job_id, code, event)
		local ok, err = pcall(function()
			timeout_timer:stop()
			timeout_timer:close()
		end)

		if not ok then
			logger.error("Failed to cleanup timeout timer: " .. tostring(err))
		end

		mutex.unlock()

		if code ~= 0 then
			logger.error("Failed to fetch package info for " .. package_name)

			return
		end

		local output_str = table.concat(homepage_output, "\n")
		local success, data = pcall(vim.json.decode, output_str)

		if not success then
			logger.error("Failed to parse pnpm view output for " .. package_name)

			return
		end

		local function is_browser_friendly(url)
			return url:match("^https?://") ~= nil
		end

		local homepage_url = nil

		if data.repository then
			local repo_url = nil
			if type(data.repository) == "table" and data.repository.url then
				repo_url = data.repository.url
			elseif type(data.repository) == "string" then
				repo_url = data.repository
			end

			if repo_url and type(repo_url) == "string" and is_browser_friendly(repo_url) then
				homepage_url = repo_url
			end
		end

		if not homepage_url and data.homepage and type(data.homepage) == "string" and data.homepage ~= "" then
			homepage_url = data.homepage
		end

		if not homepage_url then
			logger.info("Package " .. package_name .. " does not have homepage info")
			return
		end

		homepage_common.open_url(homepage_url)
	end

	local docker_config = common.get_docker_config(package_config)
	local homepage_command = common.prepare_pnpm_command("pnpm view " .. package_name .. " --json", docker_config)

	if not homepage_command then
		mutex.unlock()

		return
	end

	local job_id = vim.fn.jobstart(homepage_command, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(homepage_output, line)
					end
				end
			end
		end,
		on_exit = on_exit,
	})

	if job_id <= 0 then
		mutex.unlock()

		logger.error("Failed to start job")

		return
	end

	local timeout_seconds = common.get_timeout(package_config)
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "PNPM homepage command", function()
		mutex.unlock()
	end)
end

return M
