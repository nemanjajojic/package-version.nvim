local M = {}
local composer = require("package-version.composer")

local function register_which_keys()
	local which_key = require("which-key")

	which_key.add({
		{
			"<leader>p",
			group = "Package Version",
			icon = {
				icon = "󰙅",
				color = "green",
			},
			vim.keymap.set("n", "<leader>pc", function()
				composer.show_package_version_floaty_window()
			end, {
				noremap = true,
				silent = true,
				desc = "Composer",
			}),
			vim.keymap.set("n", "<leader>pv", function()
				composer.show_package_version_virtual_text()
			end, {
				noremap = true,
				silent = true,
				desc = "Composer Virtual Line",
			}),
		},
	})
end

function M.setup()
	register_which_keys()
end

return M
