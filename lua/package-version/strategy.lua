local M = {}

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
---@return string|nil package_manager
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

---@param package_config PackageVersionValidatedConfig
M.installed = function(package_config)
	local installed = require("package-version.installed")

	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == COMPOSER_JSON_FILE_NAME then
		installed.run__async_composer(package_config)

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
			installed.run__async_npm(package_config)
		elseif pm == PACKAGE_MANAGER_YARN then
			installed.run_async_yarn(package_config)
		elseif pm == PACKAGE_MANAGER_PNPM then
			installed.run_async_pnpm(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.outdated = function(package_config)
	local outdated = require("package-version.outdated")

	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == COMPOSER_JSON_FILE_NAME then
		outdated.run_async_composer(package_config)

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
			outdated.run_async_npm(package_config)
		elseif pm == PACKAGE_MANAGER_YARN then
			outdated.run_async_yarn(package_config)
		elseif pm == PACKAGE_MANAGER_PNPM then
			outdated.run_async_pnpm(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.update_all = function(package_config)
	local update_all = require("package-version.update-all")

	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == COMPOSER_JSON_FILE_NAME then
		update_all.run_async_composer(package_config)

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
			update_all.run_async_npm(package_config)
		elseif pm == PACKAGE_MANAGER_YARN then
			update_all.run_async_yarn(package_config)
		elseif pm == PACKAGE_MANAGER_PNPM then
			update_all.run_async_pnpm(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.update_single = function(package_config)
	local update_single = require("package-version.update-single")

	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == COMPOSER_JSON_FILE_NAME then
		update_single.run_async_composer(package_config)

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
			update_single.run_async_npm(package_config)
		elseif pm == PACKAGE_MANAGER_YARN then
			update_single.run_async_yarn(package_config)
		elseif pm == PACKAGE_MANAGER_PNPM then
			update_single.run_async_pnpm(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.warmup = function(package_config)
	local installed = require("package-version.installed")
	local outdated = require("package-version.outdated")

	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == COMPOSER_JSON_FILE_NAME then
		installed.warmup_cache_composer(package_config)
		outdated.warmup_cache_composer(package_config)

		return
	end

	if current_file_name == PACKAGE_JSON_FILE_NAME then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			return
		end

		if not pm then
			return
		end

		if pm == PACKAGE_MANAGER_NPM then
			installed.warmup_cache_npm(package_config)
			outdated.warmup_cache_npm(package_config)
		elseif pm == PACKAGE_MANAGER_YARN then
			installed.warmup_cache_yarn(package_config)
			outdated.warmup_cache_yarn(package_config)
		elseif pm == PACKAGE_MANAGER_PNPM then
			installed.warmup_cache_pnpm(package_config)
			outdated.warmup_cache_pnpm(package_config)
		end

		return
	end
end

return M
