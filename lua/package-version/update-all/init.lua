local M = {}

---@param package_config PackageVersionValidatedConfig
M.run_async_composer = function(package_config)
	require("package-version.update-all.composer").run_async(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.run_async_npm = function(package_config)
	require("package-version.update-all.npm").run_async(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.run_async_yarn = function(package_config)
	require("package-version.update-all.yarn").run_async(package_config)
end

---@param package_config PackageVersionValidatedConfig
M.run_async_pnpm = function(package_config)
	require("package-version.update-all.pnpm").run_async(package_config)
end

return M
