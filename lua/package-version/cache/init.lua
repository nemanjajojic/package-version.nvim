local logger = require("package-version.utils.logger")
local const = require("package-version.utils.const")

local M = {
	PACKAGE_MANAGER = const.PACKAGE_MANAGER,
	OPERATION = {
		INSTALLED = "installed",
		OUTDATED = "outdated",
	},
	DEFAULT_TTL = {
		installed = const.DEFAULT_VALUES.CACHE_TTL_INSTALLED,
		outdated = const.DEFAULT_VALUES.CACHE_TTL_OUTDATED,
	},
}

local cache = require("package-version.cache.in-memory-cache")
local warmup = require("package-version.cache.warmup")

cache.set_default_ttl(M.DEFAULT_TTL)

M.get = cache.get
M.set = cache.set
M.invalidate = cache.invalidate
M.invalidate_package_manager = cache.invalidate_package_manager
M.get_ttl = cache.get_ttl
M.is_enabled = cache.is_enabled
M.run_warmup = warmup.run_warmap

M.clear_all = function()
	cache.clear_all()

	logger.info("Plugin cache cleared!")
end

M.stats = function()
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
end

return M
