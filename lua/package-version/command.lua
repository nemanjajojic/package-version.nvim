local M = {}

local strategy = require("package-version.strategy")
local cache = require("package-version.cache")
local logger = require("package-version.utils.logger")

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

	create_command("PackageVersionClearCache", function()
		cache.clear_all()

		logger.info("Plugin cache is cleared!")
	end, "Clear all package version cache")

	create_command("PackageVersionCacheStats", function()
		local stats = cache.stats()

		if #stats.items == 0 then
			logger.info("Cache is empty")
			return
		end

		local message = "Cache items:"
		for _, item in ipairs(stats.items) do
			local status = item.expired and "expired" or "valid"
			message = message .. string.format("\n  %s: %s", item.key, status)
		end

		logger.info(message)
	end, "Show cache statistics")
end

return M
