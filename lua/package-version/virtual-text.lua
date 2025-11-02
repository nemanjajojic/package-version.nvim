local M = {}

local file = require("package-version.file")

local is_virtual_line_visible = false

M.toggle_package_version_virtual_text = function(packages, file_name, namespace)
	if vim.fn.expand("%:t") ~= file_name then
		vim.notify("This command can only be used inside of " .. file_name .. " file", vim.log.levels.ERROR)

		return
	end

	local namespace_id = vim.api.nvim_create_namespace(namespace)

	if is_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		is_virtual_line_visible = false

		return
	end

	for package_name, package_version in pairs(packages) do
		local line_number = file.does_buffer_contain_string(package_name)

		if line_number then
			vim.api.nvim_buf_set_extmark(0, namespace_id, line_number - 1, 0, {
				virt_text = { { "  " .. package_version, "Comment" } },
				virt_text_pos = "eol",
			})
		end
	end

	is_virtual_line_visible = true
end

return M
