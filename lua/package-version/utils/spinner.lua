local M = {}

local logger = require("package-version.utils.logger")

local config = {
	spinner_frames = {
		minimal = {
			"  ⠋",
			"  ⠙",
			"  ⠹",
			"  ⠸",
			"  ⠼",
			"  ⠴",
			"  ⠦",
			"  ⠧",
			"  ⠇",
			"  ⠏",
		},
		ball = {
			"( ●    )",
			"(  ●   )",
			"(   ●  )",
			"(    ● )",
			"(     ●)",
			"(    ● )",
			"(   ●  )",
			"(  ●   )",
			"( ●    )",
			"(●     )",
		},
		pacman = {
			"( 󰮯 .......... )",
			"(  ● ......... )",
			"(   󰮯 ........ )",
			"(    ● ....... )",
			"(     󰮯 ...... )",
			"(      ● ..... )",
			"(       󰮯 .... )",
			"(        ● ... )",
			"(         󰮯 .. )",
			"(          ● . )",
			"(           󰮯  )",
			"(            . )",
			"(           .. )",
			"(          ... )",
			"(         .... )",
			"(        ..... )",
			"(       ...... )",
			"(      ....... )",
			"(     ........ )",
			"(    ......... )",
			"(   .......... )",
			"(  ........... )",
			"( ............ )",
		},
		space = {
			"(           󰯉  )",
			"(          󰯉   )",
			"(         󰯉    )",
			"(        󰯉     )",
			"(       󰯉      )",
			"(      󰯉       )",
			"(  >   󰯉       )",
			"(   >   󰯉      )",
			"(     >  󰯉     )",
			"(       > 󰯉    )",
			"(         >󰯉   )",
			"(           > )",
			"(             )",
			"(             )",
		},
		dino = {
			"[ ..... 󱍢 ....󰶵 ]",
			"[ ..... 󱍢 ...󰶵. ]",
			"[ ..... 󱍢 ..󰶵.. ]",
			"[ ..... 󱍢 .󰶵... ]",
			"[ ..... 󱍢 󰶵.... ]",
			"[ ..... 󱍢 ..... ]",
			"[ ....󰶵 󱍢 ..... ]",
			"[ ...󰶵. 󱍢 ..... ]",
			"[ ..󰶵.. 󱍢 ..... ]",
			"[ .󰶵... 󱍢 ..... ]",
			"[ 󰶵.... 󱍢 ..... ]",
			"[ ..... 󱍢 ..... ]",
		},
	},
}

local spinner_timer = nil
local spinner_buffer = nil
local spinner_window = nil

---@param spinner_config? SpinnerValidatedConfig
function M.show(spinner_config)
	local window_config = {
		relative = "editor",
		style = "minimal",
		width = 29,
		height = 1,
		column = 1,
		row = 0,
	}

	spinner_buffer = vim.api.nvim_create_buf(false, true)
	spinner_window = vim.api.nvim_open_win(spinner_buffer, false, {
		relative = window_config.relative,
		style = window_config.style,
		width = window_config.width,
		height = window_config.height,
		col = vim.o.columns - window_config.column,
		row = window_config.row,
	})

	local spinner_type = spinner_config and spinner_config.type or "space"

	local spinner_index = #config.spinner_frames[spinner_type]

	spinner_timer = vim.uv.new_timer()

	if not spinner_timer then
		logger.error("Failed to create spinner timer")

		return
	end

	spinner_timer:start(
		0,
		100,
		vim.schedule_wrap(function()
			if vim.api.nvim_buf_is_valid(spinner_buffer) then
				vim.api.nvim_buf_set_lines(
					spinner_buffer,
					0,
					-1,
					false,
					{ "Please Wait " .. config.spinner_frames[spinner_type][spinner_index] }
				)
			end
			spinner_index = spinner_index % #config.spinner_frames[spinner_type] + 1
		end)
	)
end

---@param message? string
function M.hide(message)
	if spinner_timer then
		spinner_timer:stop()
		spinner_timer:close()

		spinner_timer = nil

		if spinner_window then
			vim.api.nvim_win_close(spinner_window, true)
		end

		if spinner_buffer then
			vim.api.nvim_buf_delete(spinner_buffer, { force = true })
		end

		if message then
			logger.info(message)
		end
	end
end

return M
