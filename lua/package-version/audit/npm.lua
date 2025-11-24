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

	table.insert(lines, "Security Audit Summary")
	table.insert(lines, "──────────────────────")
	table.insert(lines, "")

	if data.metadata then
		local meta = data.metadata
		local vulnerabilities = meta.vulnerabilities or {}

		if vulnerabilities.total and vulnerabilities.total > 0 then
			table.insert(lines, string.format("Total vulnerabilities: %d", vulnerabilities.total))
			table.insert(lines, "")

			if vulnerabilities.critical and vulnerabilities.critical > 0 then
				table.insert(
					lines,
					string.format("%s Critical: %d", const.SEVERITY_ICONS.critical, vulnerabilities.critical)
				)
			end

			if vulnerabilities.high and vulnerabilities.high > 0 then
				table.insert(lines, string.format("%s High: %d", const.SEVERITY_ICONS.high, vulnerabilities.high))
			end

			if vulnerabilities.moderate and vulnerabilities.moderate > 0 then
				table.insert(
					lines,
					string.format("%s Moderate: %d", const.SEVERITY_ICONS.moderate, vulnerabilities.moderate)
				)
			end

			if vulnerabilities.low and vulnerabilities.low > 0 then
				table.insert(lines, string.format("%s Low: %d", const.SEVERITY_ICONS.low, vulnerabilities.low))
			end

			if vulnerabilities.info and vulnerabilities.info > 0 then
				table.insert(lines, string.format("%s Info: %d", const.SEVERITY_ICONS.info, vulnerabilities.info))
			end
		else
			table.insert(lines, "✅ No vulnerabilities found!")
		end
	else
		table.insert(lines, "✅ No vulnerabilities found!")
	end

	table.insert(lines, "")

	-- Only show vulnerability details if there are actual vulnerabilities
	if data.vulnerabilities then
		local has_vulnerabilities = false
		for _, _ in pairs(data.vulnerabilities) do
			has_vulnerabilities = true
			break
		end

		if has_vulnerabilities then
			table.insert(lines, "Vulnerability Details")
			table.insert(lines, "──────────────────────")
			table.insert(lines, "")

			for pkg_name, vuln in pairs(data.vulnerabilities) do
				local severity = vuln.severity or "unknown"
				local icon = const.SEVERITY_ICONS[severity] or ""

				table.insert(lines, string.format("%s %s - %s", icon, pkg_name, severity:upper()))

				if vuln.via and type(vuln.via) == "table" then
					for _, v in ipairs(vuln.via) do
						if type(v) == "table" and v.title then
							table.insert(lines, string.format("  • %s", v.title))

							if v.url then
								table.insert(lines, string.format("    %s", v.url))
							end

							if v.cve then
								if type(v.cve) == "table" then
									table.insert(lines, string.format("    CVE: %s", table.concat(v.cve, ", ")))
								else
									table.insert(lines, string.format("    CVE: %s", v.cve))
								end
							end
						end
					end
				end

				if vuln.range then
					table.insert(lines, string.format("  Vulnerable: %s", vuln.range))
				end

				if vuln.fixAvailable then
					if type(vuln.fixAvailable) == "table" and vuln.fixAvailable.name then
						table.insert(
							lines,
							string.format(
								"  Fix: Update %s to %s",
								vuln.fixAvailable.name,
								vuln.fixAvailable.version or "latest"
							)
						)
					else
						table.insert(lines, "  Fix: Available")
					end
				else
					table.insert(lines, "  Fix: No fix available")
				end

				table.insert(lines, "")
			end
		end
	end

	return lines
end

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("NPM Audit") then
		return
	end

	logger.info("Running npm audit")

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

		-- npm audit returns non-zero when vulnerabilities are found
		-- Exit code 0: no vulnerabilities
		-- Exit code 1+: vulnerabilities found
		if code ~= 0 and #json_output == 0 then
			logger.error("Command npm audit failed with code: " .. code)
			mutex.unlock()
			window.display_error(stderr_lines, "npm audit")
			return
		end

		local formatted_lines = parse_audit_output(json_output)

		if code == 0 then
			window.display_success(formatted_lines, "npm audit")
		else
			window.display_error(formatted_lines, "npm audit")
		end

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)
	local audit_command = common.prepare_npm_command("npm audit --json", docker_config)

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
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "NPM audit command", function()
		mutex.unlock()
		spinner.hide()
	end)
end

return M
