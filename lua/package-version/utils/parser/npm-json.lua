local M = {}

local logger = require("package-version.utils.logger")

---@param stdout_lines string[]
---@return table Parsed
M.parse_json = function(stdout_lines)
	local result = {
		success = true,
		error = nil,
		added = {},
		changed = {},
		removed = {},
		audit = nil,
	}

	local json_str = table.concat(stdout_lines, "\n")

	if json_str == "" then
		return result
	end

	local ok, parsed = pcall(vim.json.decode, json_str)

	if not ok then
		logger.warning("Failed to parse npm JSON output: " .. tostring(parsed))
		return result
	end

	if parsed.error then
		result.success = false
		result.error = parsed.error
		return result
	end

	if parsed.add and #parsed.add > 0 then
		for _, pkg in ipairs(parsed.add) do
			table.insert(result.added, {
				name = pkg.name,
				version = pkg.version,
				path = pkg.path,
			})
		end
	end

	if parsed.change and #parsed.change > 0 then
		for _, change in ipairs(parsed.change) do
			table.insert(result.changed, {
				name = change.to.name,
				from_version = change.from.version,
				to_version = change.to.version,
			})
		end
	end

	if parsed.remove and #parsed.remove > 0 then
		for _, pkg in ipairs(parsed.remove) do
			table.insert(result.removed, {
				name = pkg.name,
				version = pkg.version,
			})
		end
	end

	if parsed.audit then
		result.audit = parsed.audit
	end

	return result
end

---@param parsed_data table
---@param command_name string
---@return string[] Formatted
M.format_output = function(parsed_data, command_name)
	local lines = {}

	if not parsed_data.success and parsed_data.error then
		table.insert(lines, "❌ Error: " .. (parsed_data.error.code or "Unknown"))
		table.insert(lines, "")

		if parsed_data.error.summary then
			table.insert(lines, "Summary:")
			table.insert(lines, "  " .. parsed_data.error.summary)
			table.insert(lines, "")
		end

		if parsed_data.error.detail then
			table.insert(lines, "Details:")
			local detail_lines = vim.split(parsed_data.error.detail, "\n", { plain = true })
			for _, line in ipairs(detail_lines) do
				if line ~= "" then
					table.insert(lines, "  " .. line)
				end
			end
		end

		return lines
	end

	local has_changes = false

	if #parsed_data.added > 0 then
		has_changes = true
		table.insert(lines, string.format("📦 Added Packages (%d):", #parsed_data.added))
		for _, pkg in ipairs(parsed_data.added) do
			table.insert(lines, "  ✅ " .. pkg.name .. "@" .. pkg.version)
		end
		table.insert(lines, "")
	end

	if #parsed_data.changed > 0 then
		has_changes = true
		table.insert(lines, string.format("🔄 Updated Packages (%d):", #parsed_data.changed))
		for _, pkg in ipairs(parsed_data.changed) do
			table.insert(lines, "  • " .. pkg.name .. ": " .. pkg.from_version .. " → " .. pkg.to_version)
		end
		table.insert(lines, "")
	end

	if #parsed_data.removed > 0 then
		has_changes = true
		table.insert(lines, string.format("🗑️  Removed Packages (%d):", #parsed_data.removed))
		for _, pkg in ipairs(parsed_data.removed) do
			table.insert(lines, "  ❌ " .. pkg.name .. "@" .. pkg.version)
		end
		table.insert(lines, "")
	end

	if not has_changes then
		table.insert(lines, "✅ " .. command_name .. " completed successfully")
		table.insert(lines, "")
	end

	-- Add audit summary
	if parsed_data.audit and parsed_data.audit.vulnerabilities then
		local vuln = parsed_data.audit.vulnerabilities
		table.insert(lines, "Security Audit Summary")
		table.insert(lines, "──────────────────────")
		
		if vuln.total and vuln.total > 0 then
			table.insert(lines, string.format("⚠️  %d vulnerabilities found", vuln.total))
			table.insert(lines, "")
			
			if vuln.critical and vuln.critical > 0 then
				table.insert(lines, string.format("  🚨 Critical: %d", vuln.critical))
			end
			if vuln.high and vuln.high > 0 then
				table.insert(lines, string.format("  ‼️  High: %d", vuln.high))
			end
			if vuln.moderate and vuln.moderate > 0 then
				table.insert(lines, string.format("  ⚠️  Moderate: %d", vuln.moderate))
			end
			if vuln.low and vuln.low > 0 then
				table.insert(lines, string.format("  ⚪️ Low: %d", vuln.low))
			end
		else
			table.insert(lines, "✅ No vulnerabilities found!")
		end
	end

	return lines
end

return M
