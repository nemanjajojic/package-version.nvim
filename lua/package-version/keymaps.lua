local M = {}
local composer = require("package-version.composer")

M.register_which_keys = function()
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
				desc = "Composer",
			}),
		},
	})
end

return M
