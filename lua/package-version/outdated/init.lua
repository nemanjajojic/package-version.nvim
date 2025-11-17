local M = {}

---@param package_config PackageVersionValidatedConfig
M.run_async_composer = function(package_config)
	require("package-version.outdated.composer").run_async(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.run_async_npm = function(package_config)
	require("package-version.outdated.npm").run_async(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.run_async_yarn = function(package_config)
	require("package-version.outdated.yarn").run_async(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.run_async_pnpm = function(package_config)
	require("package-version.outdated.pnpm").run_async(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.warmup_cache_composer = function(package_config)
	require("package-version.outdated.composer").warmup_cache(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.warmup_cache_npm = function(package_config)
	require("package-version.outdated.npm").warmup_cache(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.warmup_cache_yarn = function(package_config)
	require("package-version.outdated.yarn").warmup_cache(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.warmup_cache_pnpm = function(package_config)
	require("package-version.outdated.pnpm").warmup_cache(package_config)
end

return M
