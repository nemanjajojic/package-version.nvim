local M = {}

local logger = require("package-version.utils.logger")
local const = require("package-version.utils.const")

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
	if has_file(const.PACKAGE_LOCK_JSON) and (has_file(const.YARN_LOCK) or has_file(const.PNPM_LOCK_YAML)) then
		return "package-lock.json cannot coexist with yarn.lock or pnpm-lock.yaml. Please keep only one to avoid conflicts.",
			nil
	end

	if has_file(const.YARN_LOCK) and (has_file(const.PACKAGE_LOCK_JSON) or has_file(const.PNPM_LOCK_YAML)) then
		return "yarn.lock cannot coexist with package-lock.json or pnpm-lock.yaml. Please keep only one to avoid conflicts.",
			nil
	end

	if has_file(const.PNPM_LOCK_YAML) and (has_file(const.PACKAGE_LOCK_JSON) or has_file(const.YARN_LOCK)) then
		return "pnpm-lock.yaml cannot coexist with package-lock.json or yarn.lock. Please keep only one to avoid conflicts.",
			nil
	end

	if has_file(const.PACKAGE_LOCK_JSON) then
		return nil, const.PACKAGE_MANAGER.NPM
	end

	if has_file(const.YARN_LOCK) then
		return nil, const.PACKAGE_MANAGER.YARN
	end

	if has_file(const.PNPM_LOCK_YAML) then
		return nil, const.PACKAGE_MANAGER.PNPM
	end

	return nil, nil
end

---@param package_config PackageVersionValidatedConfig
M.installed = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("package-version.installed.composer").run_async(package_config)
		return
	end

	if current_file_name == const.PACKAGE_JSON then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == const.PACKAGE_MANAGER.NPM then
			require("package-version.installed.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("package-version.installed.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("package-version.installed.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.outdated = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("package-version.outdated.composer").run_async(package_config)
		return
	end

	if current_file_name == const.PACKAGE_JSON then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == const.PACKAGE_MANAGER.NPM then
			require("package-version.outdated.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("package-version.outdated.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("package-version.outdated.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.update_all = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("package-version.update-all.composer").run_async(package_config)
		return
	end

	if current_file_name == const.PACKAGE_JSON then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == const.PACKAGE_MANAGER.NPM then
			require("package-version.update-all.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("package-version.update-all.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("package-version.update-all.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.update_single = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("package-version.update-single.composer").run_async(package_config)
		return
	end

	if current_file_name == const.PACKAGE_JSON then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == const.PACKAGE_MANAGER.NPM then
			require("package-version.update-single.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("package-version.update-single.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("package-version.update-single.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.install = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("package-version.install.composer").run_async(package_config)
		return
	end

	if current_file_name == const.PACKAGE_JSON then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == const.PACKAGE_MANAGER.NPM then
			require("package-version.install.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("package-version.install.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("package-version.install.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.homepage = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("package-version.homepage.composer").run_async(package_config)
		return
	end

	if current_file_name == const.PACKAGE_JSON then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == const.PACKAGE_MANAGER.NPM then
			require("package-version.homepage.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("package-version.homepage.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("package-version.homepage.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.remove = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("package-version.remove.composer").run_async(package_config)
		return
	end

	if current_file_name == const.PACKAGE_JSON then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == const.PACKAGE_MANAGER.NPM then
			require("package-version.remove.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("package-version.remove.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("package-version.remove.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.add_new = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("package-version.add-new.composer").run_async(package_config)
		return
	end

	if current_file_name == const.PACKAGE_JSON then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == const.PACKAGE_MANAGER.NPM then
			require("package-version.add-new.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("package-version.add-new.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("package-version.add-new.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.audit = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("package-version.audit.composer").run_async(package_config)
		return
	end

	if current_file_name == const.PACKAGE_JSON then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			logger.error(error_msg)
			return
		end

		if not pm then
			no_strategy_for_package_json()
			return
		end

		if pm == const.PACKAGE_MANAGER.NPM then
			require("package-version.audit.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("package-version.audit.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("package-version.audit.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PackageVersionValidatedConfig
M.warmup = function(package_config)
	if has_file(const.COMPOSER_JSON) then
		require("package-version.installed.composer").warmup_cache(package_config)
		require("package-version.outdated.composer").warmup_cache(package_config)
	end

	if has_file(const.PACKAGE_JSON) then
		local error_msg, pm = detect_package_manager()

		if error_msg then
			return
		end

		if not pm then
			return
		end

		if pm == const.PACKAGE_MANAGER.NPM then
			require("package-version.installed.npm").warmup_cache(package_config)
			require("package-version.outdated.npm").warmup_cache(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("package-version.installed.yarn").warmup_cache(package_config)
			require("package-version.outdated.yarn").warmup_cache(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("package-version.installed.pnpm").warmup_cache(package_config)
			require("package-version.outdated.pnpm").warmup_cache(package_config)
		end
	end
end

return M
