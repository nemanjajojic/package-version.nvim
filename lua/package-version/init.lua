local M = {}
local composer = require("package-version.composer")

function M.setup()
	RegisterWhichKeys()
end

function RegisterWhichKeys()
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
				composer.show_package_version()
			end, {
				noremap = true,
				silent = true,
				desc = "Composer",
			}),
		},
	})
end

return M
