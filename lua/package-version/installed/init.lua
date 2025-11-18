local M = {}

---@param package_config PackageVersionValidatedConfig
M.run__async_composer = function(package_config)
	require("package-version.installed.composer").run_async(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.run__async_npm = function(package_config)
	require("package-version.installed.npm").run_async(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.run_async_yarn = function(package_config)
	require("package-version.installed.yarn").run_async(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.run_async_pnpm = function(package_config)
	require("package-version.installed.pnpm").run_async(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.warmup_cache_composer = function(package_config)
	require("package-version.installed.composer").warmup_cache(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.warmup_cache_npm = function(package_config)
	require("package-version.installed.npm").warmup_cache(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.warmup_cache_yarn = function(package_config)
	require("package-version.installed.yarn").warmup_cache(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.warmup_cache_pnpm = function(package_config)
	require("package-version.installed.pnpm").warmup_cache(package_config)
end

return M
