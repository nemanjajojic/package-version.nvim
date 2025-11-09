local M = {}

local strategy = require("package-version.package-manager.strategy")

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
	create_command("PackageVersionInstalled", function()
		strategy.installed(config)
	end, "Toggle instaled package version")

	create_command("PackageVersionOutdated", function()
		strategy.outdated(config)
	end, "Toglge outdated package version")
end

return M
