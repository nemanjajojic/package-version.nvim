local M = {}

local composer = require("package-version.package-manager.composer")
local npm = require("package-version.package-manager.npm")
local yarn = require("package-version.package-manager.yarn")
local logger = require("package-version.utils.logger")

local compose_json_file_name = "composer.json"
local package_json_file_name = "package.json"
local npm_lock_file_name = "package-lock.json"
local yarn_lock_file_name = "yarn.lock"

local log_no_supported_file = function()
	logger.error(
		"No supported package manager file found in the current buffer. Supprted files are: composer.json, package.json"
	)
end

local log_only_npm_is_supported = function()
	logger.error("Only NPM package manager with package-lock.json is supported currently.")
end

---@param file_name string
---@return boolean|nil
local has_file = function(file_name)
	local file_path = vim.fs.joinpath(vim.fn.getcwd(), file_name)

	local stat = (vim.uv or vim.loop).fs_stat(file_path)

	return stat and stat.type == "file"
end

---@param package_config? PackageVersionConfig
M.installed = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == compose_json_file_name then
		composer.installed(package_config)

		return
	end

	if current_file_name == package_json_file_name then
		if has_file(yarn_lock_file_name) and has_file(npm_lock_file_name) then
			logger.error(
				"Both yarn.lock and package-lock.json files are present. Please keep only one to avoid conflicts."
			)
			return
		end

		if has_file(yarn_lock_file_name) then
			yarn.installed(package_config)

			return
		end

		if has_file(npm_lock_file_name) then
			npm.installed(package_config)

			return
		end

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
		if has_file(yarn_lock_file_name) and has_file(npm_lock_file_name) then
			logger.error(
				"Both yarn.lock and package-lock.json files are present. Please keep only one to avoid conflicts."
			)
			return
		end

		if has_file(yarn_lock_file_name) then
			yarn.outdated(package_config)

			return
		end

		if has_file(npm_lock_file_name) then
			npm.outdated(package_config)

			return
		end

		return
	end

	log_no_supported_file()
end

return M
