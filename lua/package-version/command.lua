local M = {}

local composer = require("package-version.composer")
local npm = require("package-version.npm")

---@param name string
---@param callback function
---@param description string
local create_command = function(name, callback, description)
	vim.api.nvim_create_user_command(name, callback, {
		bang = false,
		nargs = 0,
		desc = description,
	})
end

---@param config? PackageVersionConfig
M.register_commands = function(config)
	create_command("ComposerPackageVersionToggle", function()
		composer.toggle_package_version_virtual_text(config)
	end, "Toggle instaled version of package via composer")

	create_command("NpmPackageVersionToggle", function()
		npm.toggle_package_version_virtual_text(config)
	end, "Toglge instaled version of package via NPM")
end

return M
