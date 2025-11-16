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
	end, "Toggle installed package version")

	create_command("PackageVersionOutdated", function()
		strategy.outdated(config)
	end, "Toggle outdated package version")

	create_command("PackageVersionUpdateAll", function()
		strategy.update_all(config)
	end, "Update all packages")

	create_command("PackageVersionUpdateSingle", function()
		strategy.update_single(config)
	end, "Update single package")
end

return M
