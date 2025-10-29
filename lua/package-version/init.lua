local M = {}
local composer = require("package-version.composer")

local function register_which_keys()
	local which_key = require("which-key")

	which_key.add({
		{
			"<leader>p",
			group = "package lock version",
			icon = {
				icon = "",
				color = "green",
			},
			vim.keymap.set("n", "<leader>pc", function()
				composer.show_package_version_virtual_text()
			end, {
				noremap = true,
				silent = true,
				desc = " Composer",
			}),
		},
	})
end

function M.setup()
	register_which_keys()
end

return M
