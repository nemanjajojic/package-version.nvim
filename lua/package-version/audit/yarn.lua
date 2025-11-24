local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")
local mutex = require("package-version.utils.mutex")
local window = require("package-version.utils.window")
local const = require("package-version.utils.const")

---Parse JSONL audit output and format for display
---Yarn audit outputs JSONL (one JSON object per line), not a single JSON blob
---@param data table Structured data with metadata and advisories
---@return string[]
local parse_audit_output = function(data)
	local lines = {}

	table.insert(lines, "Security Audit Summary")
	table.insert(lines, "──────────────────────")
	table.insert(lines, "")

	if data.metadata then
		local meta = data.metadata
		local vulnerabilities = meta.vulnerabilities or {}

		local total = (vulnerabilities.critical or 0)
			+ (vulnerabilities.high or 0)
			+ (vulnerabilities.moderate or 0)
			+ (vulnerabilities.low or 0)
			+ (vulnerabilities.info or 0)

		if total > 0 then
			table.insert(lines, string.format("Total vulnerabilities: %d", total))
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

	if data.advisories and #data.advisories > 0 then
		table.insert(lines, "Vulnerability Details")
		table.insert(lines, "──────────────────────")
		table.insert(lines, "")

		for _, advisory in ipairs(data.advisories) do
			local severity = advisory.severity or "unknown"
			local icon = const.SEVERITY_ICONS[severity] or ""

			table.insert(lines, string.format("%s %s - %s", icon, advisory.module_name or "unknown", severity:upper()))

			if advisory.title then
				table.insert(lines, string.format("  • %s", advisory.title))
			end

			if advisory.url then
				table.insert(lines, string.format("    %s", advisory.url))
			end

			if advisory.cves then
				if type(advisory.cves) == "table" and #advisory.cves > 0 then
					table.insert(lines, string.format("    CVE: %s", table.concat(advisory.cves, ", ")))
				elseif type(advisory.cves) == "string" then
					table.insert(lines, string.format("    CVE: %s", advisory.cves))
				end
			end

			if advisory.vulnerable_versions then
				table.insert(lines, string.format("  Vulnerable: %s", advisory.vulnerable_versions))
			end

			if advisory.patched_versions then
				table.insert(lines, string.format("  Fix: Update to %s", advisory.patched_versions))
			end

			table.insert(lines, "")
		end
	end

	return lines
end

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("Yarn Audit") then
		return
	end

	logger.info("Running yarn audit")

	local timeout_timer
	local stderr_lines = {}
	local advisories = {}
	local metadata = nil

	local on_exit = function(job_id, code, event)
		local ok, err = pcall(function()
			timeout_timer:stop()
			timeout_timer:close()
		end)

		if not ok then
			logger.error("Failed to cleanup timeout timer: " .. tostring(err))
		end

		spinner.hide()

		-- yarn audit returns non-zero when vulnerabilities are found
		-- Exit code 0: no vulnerabilities
		-- Exit code 1+: vulnerabilities found or error
		if code ~= 0 and not metadata and #advisories == 0 then
			logger.error("Command yarn audit failed with code: " .. code)
			mutex.unlock()
			window.display_error(stderr_lines, "yarn audit")
			return
		end

		local audit_data = {
			metadata = metadata,
			advisories = advisories,
		}

		local formatted_lines = parse_audit_output(audit_data)

		if code == 0 then
			window.display_success(formatted_lines, "yarn audit")
		else
			window.display_error(formatted_lines, "yarn audit")
		end

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)
	local audit_command = common.prepare_yarn_command("yarn audit --json", docker_config)

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
					if line ~= "" and line:find('"type":"audit') then
						local ok, json_obj = pcall(vim.json.decode, line)
						if ok and json_obj.type then
							if json_obj.type == "auditAdvisory" and json_obj.data and json_obj.data.advisory then
								table.insert(advisories, json_obj.data.advisory)
							elseif json_obj.type == "auditSummary" and json_obj.data then
								metadata = json_obj.data
							end
						end
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
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "Yarn audit command", function()
		mutex.unlock()
		spinner.hide()
	end)
end

return M
