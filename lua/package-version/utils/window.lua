local M = {}

local COLOR_SUCCESS = "#a6e3a1"
local COLOR_SUCCESS_CTERM = "green"

---@param buf number
---@param confirm function
---@param cancel function
local set_common_keymaps = function(buf, confirm, cancel)
	vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
		noremap = true,
		silent = true,
		callback = confirm,
	})

	vim.api.nvim_buf_set_keymap(buf, "i", "<CR>", "", {
		noremap = true,
		silent = true,
		callback = confirm,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
		noremap = true,
		silent = true,
		callback = cancel,
	})

	vim.api.nvim_buf_set_keymap(buf, "i", "<Esc>", "", {
		noremap = true,
		silent = true,
		callback = cancel,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		noremap = true,
		silent = true,
		callback = cancel,
	})
end

---Sanitize output line by removing ANSI codes and control characters
---@param line string The line to sanitize
---@return string sanitized The cleaned line
local sanitize_line = function(line)
	if not line then
		return ""
	end

	-- Remove ANSI escape codes
	line = line:gsub("\27%[[%d;]*m", "")

	-- Remove control characters except newline and tab
	line = line:gsub("[%c]", function(c)
		if c == "\n" or c == "\t" then
			return c
		end
		return ""
	end)

	return line
end

---@param output_lines string[]
---@param title string
---@param is_error boolean
local display_output = function(output_lines, title, is_error)
	local padding_left = "    "
	local padding_right = "    "
	local total_padding = 8 -- 4 left + 4 right

	local separator_width = vim.o.columns - total_padding
	local header_separator = string.rep("=", separator_width)

	local display_lines = {
		padding_left .. title .. padding_right,
		padding_left .. header_separator .. padding_right,
		"",
	}

	for _, line in ipairs(output_lines) do
		if line and line ~= "" then
			local sanitized = sanitize_line(line)
			table.insert(display_lines, padding_left .. sanitized .. padding_right)
		end
	end

	table.insert(display_lines, "")
	table.insert(display_lines, padding_left .. header_separator .. padding_right)
	table.insert(display_lines, padding_left .. "Press  <Esc>||'q' to close this window" .. padding_right)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = true

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)
	vim.bo[buf].modifiable = false

	local height = math.min(#display_lines, 20)
	local screen_height = vim.o.lines
	height = math.min(height, math.floor(screen_height / 2))

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = vim.o.columns,
		height = height,
		row = vim.o.lines - height - 2, -- -2 for cmdline and statusline
		col = 0,
		style = "minimal",
		border = "rounded",
	})

	vim.wo[win].wrap = true
	vim.wo[win].cursorline = true

	vim.api.nvim_buf_call(buf, function()
		if is_error then
			vim.cmd([[syntax match HorizontalWindowHeader /^    Command [Ff]ailed:.*    $/]])
			vim.cmd([[highlight link HorizontalWindowHeader ErrorMsg]])
		else
			vim.cmd([[syntax match HorizontalWindowHeader /^    Command [Ss]ucceeded:.*    $/]])
			vim.cmd(
				string.format(
					[[highlight HorizontalWindowHeader guifg=%s ctermfg=%s]],
					COLOR_SUCCESS,
					COLOR_SUCCESS_CTERM
				)
			)
		end
		vim.cmd([[syntax match HorizontalWindowSeparator /^    =\+    $/]])
		vim.cmd([[syntax match HorizontalWindowHelp /^    Press .*    $/]])

		vim.cmd([[highlight link HorizontalWindowSeparator Comment]])
		vim.cmd([[highlight link HorizontalWindowHelp Comment]])
	end)

	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		noremap = true,
		silent = true,
		callback = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
		noremap = true,
		silent = true,
		callback = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end,
	})
end

---@param output_lines string[]
---@param command_name string
M.display_error = function(output_lines, command_name)
	display_output(output_lines, "Command Failed: " .. command_name, true)
end

---@param output_lines string[]
---@param command_name string
M.display_success = function(output_lines, command_name)
	display_output(output_lines, "Command Succeeded: " .. command_name, false)
end

---@param title string
---@param callback function(package_name: string|nil) Callback with package name or nil if cancelled
M.display_input = function(title, callback)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = true

	local display_lines = { " 󰏖 " }

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)

	local width = 50
	local height = 1

	-- Center the window
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		title = title,
		title_pos = "center",
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	vim.wo[win].wrap = false
	vim.wo[win].cursorline = false

	-- Set window-local highlight to make title match border color
	vim.api.nvim_set_hl(0, "FloatTitle", { link = "FloatBorder" })

	-- Position cursor after the prompt
	local prompt_len = #display_lines[1]
	vim.api.nvim_win_set_cursor(win, { 1, prompt_len })

	vim.bo[buf].modifiable = true

	-- Protect the prompt icon from deletion
	local protect_prompt = function()
		local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
		-- If the prompt was deleted, restore it
		if not line:match("^%s*󰏖%s+") then
			vim.bo[buf].modifiable = true
			vim.api.nvim_buf_set_lines(buf, 0, 1, false, { " 󰏖 " .. vim.trim(line:gsub("^%s*󰏖%s*", "")) })
			vim.bo[buf].modifiable = true
		end
		-- Prevent cursor from moving before the prompt (must be at or after prompt_len)
		local cursor = vim.api.nvim_win_get_cursor(win)
		if cursor[2] < prompt_len then
			vim.api.nvim_win_set_cursor(win, { 1, prompt_len })
		end
	end

	-- Add autocommands to protect the prompt
	local augroup = vim.api.nvim_create_augroup("PackageVersionInputProtect_" .. buf, { clear = true })
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "CursorMoved", "CursorMovedI" }, {
		group = augroup,
		buffer = buf,
		callback = protect_prompt,
	})

	local close_window = function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	local confirm = function()
		local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
		local package_name = line:sub(prompt_len + 1)
		package_name = vim.trim(package_name)

		close_window()

		if package_name ~= "" then
			callback(package_name)
		else
			callback(nil)
		end
	end

	local cancel = function()
		close_window()
		callback(nil)
	end

	set_common_keymaps(buf, confirm, cancel)

	vim.cmd("startinsert!")
end

---@param title string
---@param options table[]
---@param callback function(selected_value: any|nil) Callback with selected value or nil if cancelled
M.display_select = function(title, options, callback)
	if not options or #options == 0 then
		callback(nil)
		return
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false

	local current_index = 1
	local width = 60

	local render = function()
		local display_lines = { "" }

		for i, option in ipairs(options) do
			local prefix = i == current_index and "▶ " or "  "
			table.insert(display_lines, "    " .. prefix .. option.label)
		end

		table.insert(display_lines, "")
		table.insert(display_lines, "    ↑↓||jk Navigate  <Enter> Select  <Esc>||q Cancel")

		vim.bo[buf].modifiable = true
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)
		vim.bo[buf].modifiable = false
	end

	local height = #options + 3 -- blank + options + blank + help

	-- Center the window
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		title = title,
		title_pos = "center",
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	vim.wo[win].wrap = false
	vim.wo[win].cursorline = false

	-- Set window-local highlight to make title match border color
	vim.api.nvim_set_hl(0, "FloatTitle", { link = "FloatBorder" })

	render()

	-- Apply syntax highlighting
	vim.api.nvim_buf_call(buf, function()
		vim.cmd([[syntax match WindowSelectCursor /^    ▶ .*$/]])
		vim.cmd([[syntax match WindowSelectHelp /^    ↑↓.*$/]])

		vim.cmd(string.format([[highlight WindowSelectCursor guifg=%s ctermfg=%s]], COLOR_SUCCESS, COLOR_SUCCESS_CTERM))
		vim.cmd([[highlight link WindowSelectHelp Comment]])
	end)

	-- Close function
	local close_window = function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	local confirm = function()
		local selected = options[current_index]
		close_window()
		callback(selected.value)
	end

	local cancel = function()
		close_window()
		callback(nil)
	end

	local navigate_up = function()
		if current_index > 1 then
			current_index = current_index - 1
			render()
		end
	end

	local navigate_down = function()
		if current_index < #options then
			current_index = current_index + 1
			render()
		end
	end

	set_common_keymaps(buf, confirm, cancel)

	vim.api.nvim_buf_set_keymap(buf, "n", "k", "", {
		noremap = true,
		silent = true,
		callback = navigate_up,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "j", "", {
		noremap = true,
		silent = true,
		callback = navigate_down,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "<Up>", "", {
		noremap = true,
		silent = true,
		callback = navigate_up,
	})

	vim.api.nvim_buf_set_keymap(buf, "n", "<Down>", "", {
		noremap = true,
		silent = true,
		callback = navigate_down,
	})
end

return M
