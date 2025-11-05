local M = {}

local composer = require("package-version.composer")
local npm = require("package-version.npm")

---@param config? PackageVersionConfig
M.register_which_keys = function(config)
	local which_key = require("which-key")

	which_key.add({
		{
			"<leader>v",
			group = "package version",
			icon = {
				icon = "",
				color = "green",
			},
		},
		{
			"<leader>vc",
			group = "Composer",
			icon = {
				icon = "",
				color = "yellow",
			},
			function()
				composer.toggle_package_version_virtual_text(config)
			end,
			desc = "Current",
		},
		{
			"<leader>vn",
			group = "NPM",
			icon = {
				icon = "",
				color = "red",
			},
			function()
				npm.toggle_package_version_virtual_text(config)
			end,
			desc = "Current",
		},
	})
end

return M
