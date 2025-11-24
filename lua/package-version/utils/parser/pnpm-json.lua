local M = {}

local logger = require("package-version.utils.logger")

---@param debug_logs table[]
---@return string[] Array
local extract_added_packages = function(debug_logs)
	local packages = {}

	for _, log in ipairs(debug_logs) do
		if log.name == "pnpm:root" and log.added then
			local pkg_name = log.added.name or log.added.realName
			local version = log.added.version
			if pkg_name and version then
				table.insert(packages, pkg_name .. "@" .. version)
			end
		end
	end

	return packages
end

---Parse pnpm NDJSON output (one JSON object per line)
---@param stdout_lines string[]
---@return table Parsed
M.parse_ndjson = function(stdout_lines)
	local result = {
		debug = {},
		info = {},
		warnings = {},
		errors = {},
	}

	for _, line in ipairs(stdout_lines) do
		if line and line ~= "" then
			if line:find("^%s*{") then
				local ok, parsed = pcall(vim.json.decode, line)

				if ok and parsed and parsed.level then
					if parsed.level == "debug" then
						table.insert(result.debug, parsed)
					elseif parsed.level == "info" then
						table.insert(result.info, parsed)
					elseif parsed.level == "warn" then
						table.insert(result.warnings, parsed)
					elseif parsed.level == "error" then
						table.insert(result.errors, parsed)
					end
				elseif not ok then
					logger.warning("Failed to parse pnpm JSON line: " .. tostring(parsed))
				end
			end
		end
	end

	return result
end

---@param parsed_data table
---@param command_name string
---@return string[] Formatted
M.format_output = function(parsed_data, command_name)
	local lines = {}

	if #parsed_data.info > 0 then
		for _, log in ipairs(parsed_data.info) do
			if log.msg then
				local msg_lines = vim.split(log.msg, "\n", { plain = true })
				for _, msg_line in ipairs(msg_lines) do
					if msg_line ~= "" then
						table.insert(lines, "ℹ️  " .. msg_line)
					end
				end
			end
		end
		if #lines > 0 then
			table.insert(lines, "")
		end
	end

	if #parsed_data.warnings > 0 then
		table.insert(lines, "⚠️  Warnings:")
		for _, log in ipairs(parsed_data.warnings) do
			local msg = log.msg or log.hint or ""
			local warning_lines = vim.split(msg, "\n", { plain = true })
			for i, warning_line in ipairs(warning_lines) do
				if warning_line ~= "" then
					if i == 1 then
						table.insert(lines, "  • " .. warning_line)
					else
						table.insert(lines, "    " .. warning_line)
					end
				end
			end
		end
		table.insert(lines, "")
	end

	if #parsed_data.errors > 0 then
		table.insert(lines, "❌ Errors:")
		for _, log in ipairs(parsed_data.errors) do
			local error_msg = log.err and log.err.message or log.hint or log.msg or "Unknown error"
			local error_code = log.code or ""

			local full_error = error_code ~= "" and (error_code .. ": " .. error_msg) or error_msg

			local error_lines = vim.split(full_error, "\n", { plain = true })
			for i, error_line in ipairs(error_lines) do
				if i == 1 then
					table.insert(lines, "  • " .. error_line)
				else
					table.insert(lines, "    " .. error_line)
				end
			end
		end
		table.insert(lines, "")
	end

	local added_packages = extract_added_packages(parsed_data.debug)
	if #added_packages > 0 then
		table.insert(lines, string.format("📦 Added Packages (%d):", #added_packages))
		for _, pkg in ipairs(added_packages) do
			table.insert(lines, "  • " .. pkg)
		end
		table.insert(lines, "")
	end

	if #lines == 0 then
		table.insert(lines, "✅ " .. command_name .. " completed successfully")
	end

	return lines
end

return M
