local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")
local mutex = require("package-version.utils.mutex")
local window = require("package-version.utils.window")
local const = require("package-version.utils.const")

---@param json_str string
---@return string[]
local parse_audit_output = function(json_str)
	local ok, data = pcall(vim.json.decode, json_str)
	if not ok then
		return { "Failed to parse audit JSON output" }
	end

	local lines = {}

	if data.advisories then
		local total_count = 0
		local severity_counts = {
			critical = 0,
			high = 0,
			moderate = 0,
			low = 0,
			info = 0,
		}

		for _, advisory in ipairs(data.advisories) do
			total_count = total_count + 1
			local severity = advisory.severity or "info"
			severity_counts[severity] = (severity_counts[severity] or 0) + 1
		end

		table.insert(lines, "Security Audit Summary")
		table.insert(lines, "──────────────────────")
		table.insert(lines, "")

		if total_count > 0 then
			table.insert(lines, string.format("Total vulnerabilities: %d", total_count))
			table.insert(lines, "")

			if severity_counts.critical > 0 then
				table.insert(
					lines,
					string.format("%s Critical: %d", const.SEVERITY_ICONS.critical, severity_counts.critical)
				)
			end

			if severity_counts.high > 0 then
				table.insert(lines, string.format("%s High: %d", const.SEVERITY_ICONS.high, severity_counts.high))
			end

			if severity_counts.moderate > 0 then
				table.insert(
					lines,
					string.format("%s Moderate: %d", const.SEVERITY_ICONS.moderate, severity_counts.moderate)
				)
			end

			if severity_counts.low > 0 then
				table.insert(lines, string.format("%s Low: %d", const.SEVERITY_ICONS.low, severity_counts.low))
			end

			if severity_counts.info > 0 then
				table.insert(lines, string.format("%s Info: %d", const.SEVERITY_ICONS.info, severity_counts.info))
			end

			table.insert(lines, "")

			table.insert(lines, "Vulnerability Details")
			table.insert(lines, "──────────────────────")
			table.insert(lines, "")

			for _, advisory in ipairs(data.advisories) do
				local severity = advisory.severity or "info"
				local icon = const.SEVERITY_ICONS[severity] or ""

				local pkg_name = "unknown"
				if advisory.affectedPackage then
					pkg_name = advisory.affectedPackage
				elseif advisory.packageName then
					pkg_name = advisory.packageName
				end

				table.insert(lines, string.format("%s %s - %s", icon, pkg_name, severity:upper()))

				if advisory.title then
					table.insert(lines, string.format("  • %s", advisory.title))
				end

				if advisory.link then
					table.insert(lines, string.format("    %s", advisory.link))
				end

				if advisory.cve then
					if type(advisory.cve) == "table" then
						table.insert(lines, string.format("    CVE: %s", table.concat(advisory.cve, ", ")))
					else
						table.insert(lines, string.format("    CVE: %s", advisory.cve))
					end
				end

				if advisory.affectedVersions then
					table.insert(lines, string.format("  Vulnerable: %s", advisory.affectedVersions))
				end

				table.insert(lines, "")
			end
		else
			table.insert(lines, "✅ No vulnerabilities found!")
			table.insert(lines, "")
		end
	else
		table.insert(lines, "✅ No vulnerabilities found!")
		table.insert(lines, "")
	end

	return lines
end

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("Composer Audit") then
		return
	end

	logger.info("Running composer audit")

	local timeout_timer
	local output_lines = {}
	local stderr_lines = {}
	local json_output = ""

	local on_exit = function(job_id, code, event)
		local ok, err = pcall(function()
			timeout_timer:stop()
			timeout_timer:close()
		end)

		if not ok then
			logger.error("Failed to cleanup timeout timer: " .. tostring(err))
		end

		spinner.hide()

		-- composer audit returns non-zero when vulnerabilities are found
		-- Exit code 0: no vulnerabilities
		-- Exit code 1+: vulnerabilities found or error
		if code ~= 0 and #json_output == 0 then
			logger.error("Command composer audit failed with code: " .. code)
			mutex.unlock()
			window.display_error(stderr_lines, "composer audit")
			return
		end

		local formatted_lines = parse_audit_output(json_output)

		if code == 0 then
			window.display_success(formatted_lines, "composer audit")
		else
			window.display_error(formatted_lines, "composer audit")
		end

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)
	local audit_command = common.prepare_composer_command("composer audit --format=json", docker_config, false)

	if not audit_command then
		mutex.unlock()
		return
	end

	spinner.show(package_config.spinner)

	local job_id = vim.fn.jobstart(audit_command, {
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						json_output = json_output .. line
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
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "Composer audit command", function()
		mutex.unlock()
		spinner.hide()
	end)
end

return M
