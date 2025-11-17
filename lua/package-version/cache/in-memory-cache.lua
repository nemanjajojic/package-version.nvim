local M = {}

M.PACKAGE_MANAGER = {
	NPM = "npm",
	COMPOSER = "composer",
	YARN = "yarn",
	PNPM = "pnpm",
}

M.OPERATION = {
	INSTALLED = "installed",
	OUTDATED = "outdated",
}

---@type table<string, CacheEntry>
local cache_store = {}

local DEFAULT_TTL = {
	installed = 300,
	outdated = 300,
}

---@param package_manager string
---@param operation string
---@return string cache_key
local function generate_key(package_manager, operation)
	return string.format("%s:%s", package_manager, operation)
end

---@param entry CacheEntry
---@return boolean is_valid
local function is_valid(entry)
	if not entry then
		return false
	end

	local current_time = os.time()
	local age = current_time - entry.timestamp

	return age < entry.ttl
end

---@param package_manager string
---@param operation string
---@return any|nil data
M.get = function(package_manager, operation)
	local key = generate_key(package_manager, operation)
	local entry = cache_store[key]

	if not entry then
		return nil
	end

	if not is_valid(entry) then
		cache_store[key] = nil

		return nil
	end

	return entry.data
end

---@param package_manager string
---@param operation string
---@param data any
---@param ttl? number
M.set = function(package_manager, operation, data, ttl)
	local key = generate_key(package_manager, operation)
	local effective_ttl = ttl or DEFAULT_TTL[operation] or 300

	cache_store[key] = {
		data = data,
		timestamp = os.time(),
		ttl = effective_ttl,
	}
end

---@param package_manager string
---@param operation string
M.invalidate = function(package_manager, operation)
	local key = generate_key(package_manager, operation)

	if cache_store[key] then
		cache_store[key] = nil
	end
end

---@param package_manager string
M.invalidate_package_manager = function(package_manager)
	local count = 0

	for key, _ in pairs(cache_store) do
		if key:match("^" .. package_manager .. ":") then
			cache_store[key] = nil
			count = count + 1
		end
	end
end

M.clear_all = function()
	local count = 0
	for _ in pairs(cache_store) do
		count = count + 1
	end

	cache_store = {}
end

---@return CacheStats
M.stats = function()
	local items = {}

	for key, item in pairs(cache_store) do
		table.insert(items, {
			key = key,
			expired = not is_valid(item),
		})
	end

	return {
		items = items,
	}
end

---@param cache_config CacheValidatedConfig
---@param operation string
---@return number ttl
M.get_ttl = function(cache_config, operation)
	return cache_config.ttl[operation]
end

---@param cache_config CacheValidatedConfig
---@return boolean enabled
M.is_enabled = function(cache_config)
	return cache_config.enabled
end

return M
