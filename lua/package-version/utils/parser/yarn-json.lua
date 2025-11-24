local M = {}

local logger = require("package-version.utils.logger")

---@param stdout_lines string[]
---@return table Parsed
M.parse_jsonl = function(stdout_lines)
	local result = {
		success = {},
		warnings = {},
		errors = {},
		info = {},
		trees = {},
	}

	for _, line in ipairs(stdout_lines) do
		if line and line ~= "" then
			if line:find("^%s*{") then
				local ok, parsed = pcall(vim.json.decode, line)

				if ok and parsed and parsed.type then
					if parsed.type == "success" then
						table.insert(result.success, parsed.data)
					elseif parsed.type == "warning" then
						table.insert(result.warnings, parsed.data)
					elseif parsed.type == "error" then
						table.insert(result.errors, parsed.data)
					elseif parsed.type == "info" then
						table.insert(result.info, parsed.data)
					elseif parsed.type == "tree" then
						table.insert(result.trees, parsed.data)
					end
				elseif not ok then
					logger.warning("Failed to parse yarn JSON line: " .. tostring(parsed))
				end
			end
		end
	end

	return result
end

---@param trees table[]
---@return string[] Array
local extract_direct_dependencies = function(trees)
	local packages = {}

	for _, tree in ipairs(trees) do
		if tree.type == "newDirectDependencies" and tree.trees then
			for _, pkg in ipairs(tree.trees) do
				if pkg.name then
					table.insert(packages, pkg.name)
				end
			end
		end
	end

	return packages
end

---@param parsed_data table
---@param command_name string
---@return string[] Formatted
M.format_output = function(parsed_data, command_name)
	local lines = {}

	if #parsed_data.success > 0 then
		for _, msg in ipairs(parsed_data.success) do
			local msg_lines = vim.split(msg, "\n", { plain = true })
			for _, msg_line in ipairs(msg_lines) do
				if msg_line ~= "" then
					table.insert(lines, "✅ " .. msg_line)
				end
			end
		end
		table.insert(lines, "")
	end

	-- Add warnings
	if #parsed_data.warnings > 0 then
		table.insert(lines, "⚠️  Warnings:")
		for _, msg in ipairs(parsed_data.warnings) do
			-- Split multi-line warning messages
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

	-- Add errors
	if #parsed_data.errors > 0 then
		table.insert(lines, "❌ Errors:")
		for _, msg in ipairs(parsed_data.errors) do
			-- Split multi-line error messages (e.g., stack traces)
			local error_lines = vim.split(msg, "\n", { plain = true })
			for i, error_line in ipairs(error_lines) do
				if i == 1 then
					table.insert(lines, "  • " .. error_line)
				else
					-- Indent continuation lines
					table.insert(lines, "    " .. error_line)
				end
			end
		end
		table.insert(lines, "")
	end

	-- Extract and display direct dependencies if available
	local direct_deps = extract_direct_dependencies(parsed_data.trees)
	if #direct_deps > 0 then
		table.insert(lines, string.format("📦 Direct Dependencies (%d):", #direct_deps))
		for _, pkg in ipairs(direct_deps) do
			table.insert(lines, "  • " .. pkg)
		end
		table.insert(lines, "")
	end

	-- If no formatted output, add a generic success message
	if #lines == 0 then
		table.insert(lines, "✅ " .. command_name .. " completed successfully")
	end

	return lines
end

return M
