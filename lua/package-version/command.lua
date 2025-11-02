local M = {}

local composer = require("package-version.composer")
local npm = require("package-version.npm")

M.packge_version_command = function()
	vim.api.nvim_create_user_command("ComposerPackageVersionToggle", function()
		composer.toggle_package_version_virtual_text()
	end, {
		bang = false,
		nargs = 0,
		desc = "Toggle instaled version of package via composer",
	})

	vim.api.nvim_create_user_command("NpmPackageVersionToggole", function()
		npm.toggle_package_version_virtual_text()
	end, {
		bang = false,
		nargs = 0,
		desc = "Toglge instaled version of package via NPM",
	})
end

return M
