local M = {}

local composer = require("package-version.package-manager.composer")
local npm = require("package-version.package-manager.npm")
local yarn = require("package-version.package-manager.yarn")
local pnpm = require("package-version.package-manager.pnpm")
local logger = require("package-version.utils.logger")

local COMPOSER_JSON_FILE_NAME = "composer.json"
local PACKAGE_JSON_FILE_NAME = "package.json"
local NPM_LOCK_FILE_NAME = "package-lock.json"
local YARN_LOCK_FILE_NAME = "yarn.lock"
local PNPM_LOCK_FILE_NAME = "pnpm-lock.yaml"

local PACKAGE_MANAGER_NPM = "npm"
local PACKAGE_MANAGER_YARN = "yarn"
local PACKAGE_MANAGER_PNPM = "pnpm"

---@param file_name string
---@return boolean|nil
local has_file = function(file_name)
	local file_path = vim.fs.joinpath(vim.fn.getcwd(), file_name)

	local stat = vim.uv.fs_stat(file_path)

	return stat and stat.type == "file"
end

local log_no_supported_file = function()
	logger.error(
		"No supported package manager file found in the current buffer. Supported files are: composer.json, package.json"
	)
end

local no_strategy_for_package_json = function()
	logger.error("No package manager strategy found for package.json")
end

---@return string|nil error_message
---@return string|nil package_manager ("npm"|"yarn"|"pnpm")
local detect_package_manager = function()
	if has_file(NPM_LOCK_FILE_NAME) and (has_file(YARN_LOCK_FILE_NAME) or has_file(PNPM_LOCK_FILE_NAME)) then
		return "package-lock.json cannot coexist with yarn.lock or pnpm-lock.yaml. Please keep only one to avoid conflicts.",
			nil
	end

	if has_file(YARN_LOCK_FILE_NAME) and (has_file(NPM_LOCK_FILE_NAME) or has_file(PNPM_LOCK_FILE_NAME)) then
		return "yarn.lock cannot coexist with package-lock.json or pnpm-lock.yaml. Please keep only one to avoid conflicts.",
			nil
	end

	if has_file(PNPM_LOCK_FILE_NAME) and (has_file(NPM_LOCK_FILE_NAME) or has_file(YARN_LOCK_FILE_NAME)) then
		return "pnpm-lock.yaml cannot coexist with package-lock.json or yarn.lock. Please keep only one to avoid conflicts.",
			nil
	end

	if has_file(NPM_LOCK_FILE_NAME) then
		return nil, PACKAGE_MANAGER_NPM
	end

	if has_file(YARN_LOCK_FILE_NAME) then
		return nil, PACKAGE_MANAGER_YARN
	end

	if has_file(PNPM_LOCK_FILE_NAME) then
		return nil, PACKAGE_MANAGER_PNPM
	end

	return nil, nil
end

---@param package_config? PackageVersionConfig
M.installed = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == COMPOSER_JSON_FILE_NAME then
		composer.installed(package_config)

		return
	end

	if current_file_name == PACKAGE_JSON_FILE_NAME then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == PACKAGE_MANAGER_NPM then
			npm.installed(package_config)
		elseif pm == PACKAGE_MANAGER_YARN then
			yarn.installed(package_config)
		elseif pm == PACKAGE_MANAGER_PNPM then
			pnpm.installed(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config? PackageVersionConfig
M.outdated = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == COMPOSER_JSON_FILE_NAME then
		composer.outdated(package_config)

		return
	end

	if current_file_name == PACKAGE_JSON_FILE_NAME then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == PACKAGE_MANAGER_NPM then
			npm.outdated(package_config)
		elseif pm == PACKAGE_MANAGER_YARN then
			yarn.outdated(package_config)
		elseif pm == PACKAGE_MANAGER_PNPM then
			pnpm.outdated(package_config)
		end

		return
	end

	log_no_supported_file()
end

M.update_all = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == COMPOSER_JSON_FILE_NAME then
		composer.update_all(package_config)

		return
	end

	if current_file_name == PACKAGE_JSON_FILE_NAME then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == PACKAGE_MANAGER_NPM then
			npm.update_all(package_config)
		elseif pm == PACKAGE_MANAGER_YARN then
			yarn.update_all(package_config)
		elseif pm == PACKAGE_MANAGER_PNPM then
			pnpm.update_all(package_config)
		end

		return
	end

	log_no_supported_file()
end

M.update_single = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == COMPOSER_JSON_FILE_NAME then
		composer.update_single(package_config)

		return
	end

	if current_file_name == PACKAGE_JSON_FILE_NAME then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == PACKAGE_MANAGER_NPM then
			npm.update_single(package_config)
		elseif pm == PACKAGE_MANAGER_YARN then
			yarn.update_single(package_config)
		elseif pm == PACKAGE_MANAGER_PNPM then
			pnpm.update_single(package_config)
		end

		return
	end

	log_no_supported_file()
end

return M
