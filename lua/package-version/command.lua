local M = {}

local composer = require("package-version.composer")

M.composer_packge_version_command = function()
	vim.api.nvim_create_user_command("ComposerPackageVersion", function()
		composer.show_package_version_virtual_text()
	end, {
		bang = false,
		nargs = 0,
		desc = "Display instaled version of package in composer",
	})
end

return M
