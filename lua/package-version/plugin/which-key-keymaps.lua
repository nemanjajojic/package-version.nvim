local M = {}

local composer = require("package-version.plugin.composer")
local npm = require("package-version.plugin.npm")

M.register_which_keys = function()
	local which_key = require("which-key")

	which_key.add({
		{
			"<leader>v",
			group = "package lock version",
			icon = {
				icon = "",
				color = "green",
			},
			vim.keymap.set("n", "<leader>vc", function()
				composer.toggle_package_version_virtual_text()
			end, {
				noremap = true,
				silent = true,
				desc = "Composer",
			}),
			vim.keymap.set("n", "<leader>vn", function()
				npm.toggle_package_version_virtual_text()
			end, {
				noremap = true,
				silent = true,
				desc = "NPM",
			}),
		},
	})
end

return M
