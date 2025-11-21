local M = {}

local logger = require("package-version.utils.logger")
local spinner = require("package-version.utils.spinner")
local common = require("package-version.utils.common")
local mutex = require("package-version.utils.mutex")
local cache = require("package-version.cache")

local is_installed_virtual_line_visible = false

---@param packages table<string, {version: string}>
---@param namespace_id number
---@param color_config table
local function display_packages(packages, namespace_id, color_config)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

	for line_number, line_content in ipairs(lines) do
		local package_name = common.get_package_name_from_line_json(line_content)
		local current_package = packages[package_name]

		if current_package ~= nil then
			common.set_virtual_text(line_number, current_package.version, namespace_id, "", color_config.current)
		end
	end
end

---@param package_config PackageVersionValidatedConfig
M.run_async = function(package_config)
	if not mutex.try_lock("PNPM Installed") then
		return
	end

	local namespace_id = vim.api.nvim_create_namespace("PNPM Installed")

	if is_installed_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

		spinner.hide()

		is_installed_virtual_line_visible = false

		mutex.unlock()

		return
	end

	local color_config = common.get_default_color_config(package_config)
	local cache_config = package_config.cache

	if cache.is_enabled(cache_config) then
		local cached_packages = cache.get(cache.PACKAGE_MANAGER.PNPM, cache.OPERATION.INSTALLED)
		if cached_packages then
			display_packages(cached_packages, namespace_id, color_config)

			is_installed_virtual_line_visible = true

			mutex.unlock()

			return
		end
	end

	local installed = {}

	local timeout_timer

	local on_exit = function(job_id, code, event)
		local ok, err = pcall(function()
			timeout_timer:stop()
			timeout_timer:close()
		end)

		if not ok then
			logger.error("Failed to cleanup timeout timer: " .. tostring(err))
		end

		if code ~= 0 then
			logger.error("Command 'pnpm list' failed with code: " .. code)

			spinner.hide()

			mutex.unlock()

			return
		end

		local json_str = table.concat(installed, "\n")

		---@type table<{dependencies: table<string, {version: string}>, devDependencies: table<string, {version: string}>}>
		local result

		ok, result = pcall(vim.fn.json_decode, json_str)

		if not ok then
			logger.error("JSON decode error: " .. result)

			return
		end

		---@type table<string, {version: string}>
		local packages = vim.tbl_extend("force", result[1].dependencies, result[1].devDependencies)

		if cache.is_enabled(cache_config) then
			local ttl = cache.get_ttl(cache_config, cache.OPERATION.INSTALLED)

			cache.set(cache.PACKAGE_MANAGER.PNPM, cache.OPERATION.INSTALLED, packages, ttl)
		end

		display_packages(packages, namespace_id, color_config)

		spinner.hide()

		is_installed_virtual_line_visible = true

		mutex.unlock()
	end

	local docker_config = common.get_docker_config(package_config)

	local installed_command = common.prepare_pnpm_command("pnpm list --depth=0 --json", docker_config)

	if not installed_command then
		mutex.unlock()

		return
	end

	spinner.show(package_config.spinner)

	local job_id = vim.fn.jobstart(installed_command, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(installed, line)
					end
				end
			end
		end,
		on_exit = on_exit,
	})

	if job_id <= 0 then
		mutex.unlock()

		spinner.hide()

		logger.error("Failed to start job")

		return
	end

	local timeout_seconds = common.get_timeout(package_config)
	timeout_timer = common.start_job_timeout(job_id, timeout_seconds, "PNPM installed command", function()
		mutex.unlock()

		spinner.hide()
	end)
end

---@param cache_config CacheValidatedConfig
---@param operation string
---@return number warmup_ttl
local function get_warmup_ttl(cache_config, operation)
	return cache_config.warmup.ttl[operation]
end

---@param package_config PackageVersionValidatedConfig
M.warmup_cache = function(package_config)
	local cache_config = package_config.cache

	if not cache.is_enabled(cache_config) then
		return
	end

	local warmup_ttl = get_warmup_ttl(cache_config, cache.OPERATION.INSTALLED)

	if warmup_ttl == 0 then
		return
	end

	local cached_packages = cache.get(cache.PACKAGE_MANAGER.PNPM, cache.OPERATION.INSTALLED)
	if cached_packages then
		return
	end

	local docker_config = common.get_docker_config(package_config)
	local installed_command = common.prepare_pnpm_command("pnpm list --depth=0 --json", docker_config)

	if not installed_command then
		return
	end

	local installed = {}

	vim.fn.jobstart(installed_command, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						table.insert(installed, line)
					end
				end
			end
		end,
		on_exit = function(_, code, _)
			if code ~= 0 then
				return
			end

			local json_str = table.concat(installed, "\n")
			local ok, result = pcall(vim.fn.json_decode, json_str)

			if not ok or type(result) ~= "table" then
				return
			end

			---@type table<string, {version: string}>
			local packages = vim.tbl_extend("force", result[1].dependencies, result[1].devDependencies)

			warmup_ttl = get_warmup_ttl(cache_config, cache.OPERATION.INSTALLED)

			cache.set(cache.PACKAGE_MANAGER.PNPM, cache.OPERATION.INSTALLED, packages, warmup_ttl)
		end,
	})
end

return M
