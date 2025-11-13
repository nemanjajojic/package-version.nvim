local M = {}

local composer = require("package-version.package-manager.composer")
local npm = require("package-version.package-manager.npm")
local yarn = require("package-version.package-manager.yarn")
local pnpm = require("package-version.package-manager.pnpm")
local logger = require("package-version.utils.logger")

local compose_json_file_name = "composer.json"
local package_json_file_name = "package.json"
local npm_lock_file_name = "package-lock.json"
local yarn_lock_file_name = "yarn.lock"
local pnpm_lock_file_name = "pnpm-lock.yaml"

---@param file_name string
---@return boolean|nil
local has_file = function(file_name)
	local file_path = vim.fs.joinpath(vim.fn.getcwd(), file_name)

	local stat = (vim.uv or vim.loop).fs_stat(file_path)

	return stat and stat.type == "file"
end

local log_no_supported_file = function()
	logger.error(
		"No supported package manager file found in the current buffer. Supprted files are: composer.json, package.json"
	)
end

local no_strategy_for_package_json = function()
	logger.error("No package manager strategy found for package.json")
end

---@param package_config? PackageVersionConfig
M.installed = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == compose_json_file_name then
		composer.installed(package_config)

		return
	end

	if current_file_name == package_json_file_name then
		if has_file(npm_lock_file_name) and (has_file(yarn_lock_file_name) or has_file(pnpm_lock_file_name)) then
			logger.error(
				"package-lock.json cannot coexist with yarn.lock or pnpm-lock.yaml. Please keep only one to avoid conflicts."
			)

			return
		end

		if has_file(yarn_lock_file_name) and (has_file(npm_lock_file_name) or has_file(pnpm_lock_file_name)) then
			logger.error(
				"yarn.lock cannot coexist with package-lock.json or pnpm-lock.yaml. Please keep only one to avoid conflicts."
			)

			return
		end

		if has_file(pnpm_lock_file_name) and (has_file(npm_lock_file_name) or has_file(yarn_lock_file_name)) then
			logger.error(
				"pnpm-lock.yaml cannot coexist with package-lock.json or yarn.lock. Please keep only one to avoid conflicts."
			)

			return
		end

		if has_file(npm_lock_file_name) then
			npm.installed(package_config)

			return
		end

		if has_file(yarn_lock_file_name) then
			yarn.installed(package_config)

			return
		end

		if has_file(pnpm_lock_file_name) then
			pnpm.installed(package_config)

			return
		end

		no_strategy_for_package_json()

		return
	end

	log_no_supported_file()
end

---@param package_config? PackageVersionConfig
M.outdated = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == compose_json_file_name then
		composer.outated(package_config)

		return
	end

	if current_file_name == package_json_file_name then
		if has_file(npm_lock_file_name) and (has_file(yarn_lock_file_name) or has_file(pnpm_lock_file_name)) then
			logger.error(
				"package-lock.json cannot coexist with yarn.lock or pnpm-lock.yaml. Please keep only one to avoid conflicts."
			)

			return
		end

		if has_file(yarn_lock_file_name) and (has_file(npm_lock_file_name) or has_file(pnpm_lock_file_name)) then
			logger.error(
				"yarn.lock cannot coexist with package-lock.json or pnpm-lock.yaml. Please keep only one to avoid conflicts."
			)

			return
		end

		if has_file(pnpm_lock_file_name) and (has_file(npm_lock_file_name) or has_file(yarn_lock_file_name)) then
			logger.error(
				"pnpm-lock.yaml cannot coexist with package-lock.json or yarn.lock. Please keep only one to avoid conflicts."
			)

			return
		end

		if has_file(npm_lock_file_name) then
			npm.outdated(package_config)

			return
		end

		if has_file(yarn_lock_file_name) then
			yarn.outdated(package_config)

			return
		end

		if has_file(pnpm_lock_file_name) then
			pnpm.outdated(package_config)

			return
		end

		no_strategy_for_package_json()

		return
	end

	log_no_supported_file()
end

return M
