local M = {}

---@return integer count
local function check_local_managers()
	local count = 0

	if vim.fn.executable("composer") == 1 then
		vim.health.ok("Local Composer is found")
		count = count + 1
	else
		vim.health.info("Composer: not found in PATH")
	end

	if vim.fn.executable("npm") == 1 then
		vim.health.ok("Local npm is found")
		count = count + 1
	else
		vim.health.info("npm: not found in PATH")
	end

	if vim.fn.executable("pnpm") == 1 then
		vim.health.ok("Local pnpm is found")
		count = count + 1
	else
		vim.health.info("pnpm: not found in PATH")
	end

	if vim.fn.executable("yarn") == 1 then
		vim.health.ok("Local yarn is found")
		count = count + 1
	else
		vim.health.info("yarn: not found in PATH")
	end

	return count
end

---@param docker_config DockerValidatedConfig
---@return integer count
local function check_docker_containers(docker_config)
	local count = 0

	if docker_config.composer_container_name and docker_config.composer_container_name ~= "" then
		vim.health.ok(string.format("Composer container: %s", docker_config.composer_container_name))
		count = count + 1
	else
		vim.health.info("Composer container: not configured")
	end

	if docker_config.npm_container_name and docker_config.npm_container_name ~= "" then
		vim.health.ok(string.format("npm container: %s", docker_config.npm_container_name))
		count = count + 1
	else
		vim.health.info("npm container: not configured")
	end

	if docker_config.pnpm_container_name and docker_config.pnpm_container_name ~= "" then
		vim.health.ok(string.format("pnpm container: %s", docker_config.pnpm_container_name))
		count = count + 1
	else
		vim.health.info("pnpm container: not configured")
	end

	if docker_config.yarn_container_name and docker_config.yarn_container_name ~= "" then
		vim.health.ok(string.format("yarn container: %s", docker_config.yarn_container_name))
		count = count + 1
	else
		vim.health.info("yarn container: not configured")
	end

	return count
end

function M.check()
	local plugin = require("package-version")

	-- =============================================================================
	-- SECTION 1: Configuration Validation
	-- =============================================================================
	vim.health.start("Configuration Validation")

	vim.health.ok("Configuration is valid")

	if plugin.config.spinner then
		vim.health.info("Spinner type: " .. plugin.config.spinner.type)
	end

	vim.health.info(string.format("Command timeout: %d seconds", plugin.config.timeout))

	local cache_enabled = plugin.config.cache.enabled

	if cache_enabled then
		vim.health.ok("Cache: enabled")
		local installed_ttl = plugin.config.cache.ttl.installed
		local outdated_ttl = plugin.config.cache.ttl.outdated
		vim.health.info(string.format("  installed TTL: %d seconds", installed_ttl))
		vim.health.info(string.format("  outdated TTL: %d seconds", outdated_ttl))

		if installed_ttl < 0 or installed_ttl > 3600 then
			vim.health.warn(string.format("installed TTL (%d) is outside recommended range (0-3600)", installed_ttl))
		end
		if outdated_ttl < 0 or outdated_ttl > 3600 then
			vim.health.warn(string.format("outdated TTL (%d) is outside recommended range (0-3600)", outdated_ttl))
		end
	else
		vim.health.info("Cache: disabled")
	end

	vim.health.info("Color configuration:")
	vim.health.info(string.format("  current: %s", plugin.config.color.current))
	vim.health.info(string.format("  latest: %s", plugin.config.color.latest))
	vim.health.info(string.format("  wanted: %s", plugin.config.color.wanted))
	vim.health.info(string.format("  abandoned: %s", plugin.config.color.abandoned))

	if plugin.config.docker then
		vim.health.info("Docker mode: enabled")
		local container_count = 0
		for key, value in pairs(plugin.config.docker) do
			if value and value ~= "" then
				vim.health.info(string.format("  %s: %s", key, value))
				container_count = container_count + 1
			end
		end
		if container_count == 0 then
			vim.health.warn("Docker config exists but no containers configured")
		end
	else
		vim.health.info("Docker mode: disabled (using local package managers)")
	end

	-- =============================================================================
	-- SECTION 2: Package Manager Availability
	-- =============================================================================
	vim.health.start("Package Manager Availability")

	local has_docker = vim.fn.executable("docker") == 1
	local docker_config = plugin.config.docker
	local has_docker_config = docker_config ~= nil

	if has_docker_config and not has_docker then
		vim.health.error("Docker configuration is set but docker executable not found", {
			"Install Docker: https://docs.docker.com/get-docker/",
			"Or remove docker configuration from setup() to use local package managers",
		})
		return
	end

	if has_docker_config and has_docker then
		vim.health.ok("Docker mode: docker executable found")

		---@cast docker_config DockerValidatedConfig
		local container_count = check_docker_containers(docker_config)

		if container_count == 0 then
			vim.health.error("Docker configuration exists but no containers are configured", {
				"Set at least one container in your docker config:",
				"  - composer_container_name",
				"  - npm_container_name",
				"  - pnpm_container_name",
				"  - yarn_container_name",
				"Or remove docker configuration to use local package managers",
			})
			return
		end

		vim.health.ok(string.format("Docker mode ready: %d container(s) configured", container_count))
		return
	end

	vim.health.info("Local mode: checking for package managers in PATH")

	local manager_count = check_local_managers()

	if manager_count == 0 then
		vim.health.error("No package managers available", {
			"Install at least one package manager:",
			"  - Composer: https://getcomposer.org/",
			"  - npm: https://nodejs.org/",
			"  - pnpm: https://pnpm.io/",
			"  - yarn: https://yarnpkg.com/",
			"Or configure Docker containers in setup({ docker = { ... } })",
		})
		return
	end

	vim.health.ok(string.format("Local mode ready: %d package manager(s) available", manager_count))
end

return M
