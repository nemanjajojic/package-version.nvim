local M = {}

local logger = require("pkgpeek.utils.logger")
local const = require("pkgpeek.utils.const")

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

---@param package_config PkgPeekValidatedConfig
M.installed = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("pkgpeek.installed.composer").run_async(package_config)
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
			require("pkgpeek.installed.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("pkgpeek.installed.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("pkgpeek.installed.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PkgPeekValidatedConfig
M.outdated = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("pkgpeek.outdated.composer").run_async(package_config)
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
			require("pkgpeek.outdated.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("pkgpeek.outdated.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("pkgpeek.outdated.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PkgPeekValidatedConfig
M.update_all = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("pkgpeek.update-all.composer").run_async(package_config)
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
			require("pkgpeek.update-all.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("pkgpeek.update-all.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("pkgpeek.update-all.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PkgPeekValidatedConfig
M.update_single = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("pkgpeek.update-single.composer").run_async(package_config)
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
			require("pkgpeek.update-single.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("pkgpeek.update-single.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("pkgpeek.update-single.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PkgPeekValidatedConfig
M.install = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("pkgpeek.install.composer").run_async(package_config)
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
			require("pkgpeek.install.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("pkgpeek.install.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("pkgpeek.install.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PkgPeekValidatedConfig
M.homepage = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("pkgpeek.homepage.composer").run_async(package_config)
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
			require("pkgpeek.homepage.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("pkgpeek.homepage.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("pkgpeek.homepage.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PkgPeekValidatedConfig
M.remove = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("pkgpeek.remove.composer").run_async(package_config)
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
			require("pkgpeek.remove.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("pkgpeek.remove.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("pkgpeek.remove.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PkgPeekValidatedConfig
M.add_new = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("pkgpeek.add-new.composer").run_async(package_config)
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
			require("pkgpeek.add-new.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("pkgpeek.add-new.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("pkgpeek.add-new.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PkgPeekValidatedConfig
M.audit = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("pkgpeek.audit.composer").run_async(package_config)
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
			require("pkgpeek.audit.npm").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("pkgpeek.audit.yarn").run_async(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("pkgpeek.audit.pnpm").run_async(package_config)
		end

		return
	end

	log_no_supported_file()
end

---@param package_config PkgPeekValidatedConfig
M.bump = function(package_config)
	local current_file_name = vim.fn.expand("%:t")

	if current_file_name == const.COMPOSER_JSON then
		require("pkgpeek.bump.composer").run_async(package_config)
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

		logger.info(pm .. " does not support composer bump (Composer-only operation)")
		return
	end

	log_no_supported_file()
end

---@param package_config PkgPeekValidatedConfig
M.warmup = function(package_config)
	if has_file(const.COMPOSER_JSON) then
		require("pkgpeek.installed.composer").warmup_cache(package_config)
		require("pkgpeek.outdated.composer").warmup_cache(package_config)
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
			require("pkgpeek.installed.npm").warmup_cache(package_config)
			require("pkgpeek.outdated.npm").warmup_cache(package_config)
		elseif pm == const.PACKAGE_MANAGER.YARN then
			require("pkgpeek.installed.yarn").warmup_cache(package_config)
			require("pkgpeek.outdated.yarn").warmup_cache(package_config)
		elseif pm == const.PACKAGE_MANAGER.PNPM then
			require("pkgpeek.installed.pnpm").warmup_cache(package_config)
			require("pkgpeek.outdated.pnpm").warmup_cache(package_config)
		end
	end
end

return M
