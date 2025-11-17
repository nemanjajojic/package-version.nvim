local M = {}

local strategy = require("package-version.strategy")

---@type table<number, number>
local last_warmup_time = {}

---@param cache_config CacheValidatedConfig
---@return boolean
local function is_warmup_enabled(cache_config)
	if cache_config.enabled == false then
		return false
	end

	local installed_ttl = cache_config.warmup.ttl.installed
	local outdated_ttl = cache_config.warmup.ttl.outdated

	return installed_ttl > 0 or outdated_ttl > 0
end

---@param cache_config CacheValidatedConfig
---@return number
local function get_debounce_ms(cache_config)
	return cache_config.warmup.debounce_ms
end

---@param package_config PackageVersionValidatedConfig
local function debounced_warmup(package_config)
	local cache_config = package_config.cache

	if not is_warmup_enabled(cache_config) then
		return
	end

	local bufer_number = vim.api.nvim_get_current_buf()
	local current_time = vim.uv.now()
	local debounce_ms = get_debounce_ms(cache_config)

	if last_warmup_time[bufer_number] then
		local time_since_last_warmup = current_time - last_warmup_time[bufer_number]
		if time_since_last_warmup < debounce_ms then
			return
		end
	end

	last_warmup_time[bufer_number] = current_time

	vim.defer_fn(function()
		if not vim.api.nvim_buf_is_valid(bufer_number) then
			return
		end

		strategy.warmup(package_config)
	end, debounce_ms)
end

---@param package_config PackageVersionValidatedConfig
M.run_warmap = function(package_config)
	local cache_config = package_config.cache

	if not is_warmup_enabled(cache_config) then
		return
	end

	local group = vim.api.nvim_create_augroup("PackageVersionWarmup", { clear = true })

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		pattern = { "package.json", "composer.json" },
		callback = function()
			debounced_warmup(package_config)
		end,
		desc = "Warmup package version cache on buffer enter",
	})
end

return M
