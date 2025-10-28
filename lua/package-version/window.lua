local M = {}

local api = vim.api

local function write_table_to_buffer(buffer, table)
	local output_str = vim.inspect(table)
	local lines = vim.split(output_str, "\n")

	vim.bo[buffer].modifiable = true

	api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

	vim.bo[buffer].modifiable = false

	vim.bo[buffer].filetype = "lua"
end

M.create_floating_window = function(table)
	local buffer = api.nvim_create_buf(false, true)

	local screen_width = api.nvim_win_get_width(0)
	local screen_height = api.nvim_win_get_height(0)

	local width = 80
	local height = 20
	local row = (screen_height - height) / 2
	local column = (screen_width - width) / 2

	local opts = {
		relative = "editor",
		row = row,
		col = column,
		width = width,
		height = height,
		border = "rounded",
		style = "minimal",
		focusable = true,
	}

	local window = api.nvim_open_win(buffer, true, opts)

	write_table_to_buffer(buffer, table)

	vim.keymap.set("n", "q", function()
		api.nvim_win_close(window, false)
	end, { buffer = buffer })
end

return M
