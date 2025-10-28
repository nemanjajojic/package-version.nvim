local M = {}

local function get_file_path(file_name)
	return vim.fs.joinpath(vim.fn.getcwd(), file_name)
end

M.get_decoded_json_file = function(file_name)
	local file_handle = io.open(get_file_path(file_name), "r")

	if not file_handle then
		vim.notify("Could not open " .. file_name .. ". File might not exist.", vim.log.levels.ERROR)

		return
	end

	local file_content = file_handle:read("*a")

	file_handle:close()

	return vim.json.decode(file_content)
end

M.has_file = function(file_name)
	local stat = (vim.uv or vim.loop).fs_stat(get_file_path(file_name))

	return stat ~= nil and stat.type == "file"
end

M.does_buffer_contain_string = function(package_name)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	for line_number, line_content in ipairs(lines) do
		if package_name == nil then
			goto continue
		end

		if string.find(line_content, '"' .. package_name .. '":', 1, true) then
			return line_number
		end

		::continue::
	end

	return nil
end

return M
