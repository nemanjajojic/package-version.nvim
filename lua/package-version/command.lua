local M = {}

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

---@param config PackageVersionValidatedConfig
M.register_commands = function(config)
	create_command("PackageVersionInstalled", function()
		require("package-version.strategy").installed(config)
	end, "Toggle installed package version")

	create_command("PackageVersionOutdated", function()
		require("package-version.strategy").outdated(config)
	end, "Toggle outdated package version")

	create_command("PackageVersionUpdateAll", function()
		require("package-version.strategy").update_all(config)
	end, "Update all packages")

	create_command("PackageVersionUpdateSingle", function()
		require("package-version.strategy").update_single(config)
	end, "Update single package")

	create_command("PackageVersionInstall", function()
		require("package-version.strategy").install(config)
	end, "Install packages from lock file")

	create_command("PackageVersionHomepage", function()
		require("package-version.strategy").homepage(config)
	end, "Open package github or homepage in browser")

	create_command("PackageVersionRemove", function()
		require("package-version.strategy").remove(config)
	end, "Remove package from project")

	create_command("PackageVersionAddNew", function()
		require("package-version.strategy").add_new(config)
	end, "Add new package to project")

	create_command("PackageVersionClearCache", function()
		require("package-version.cache").clear_all()
	end, "Clear all package version cache")

	create_command("PackageVersionCacheStats", function()
		require("package-version.cache").stats()
	end, "Show cache statistics")

	create_command("PackageVersionAudit", function()
		require("package-version.strategy").audit(config)
	end, "Run security audit on dependencies")
end

return M
