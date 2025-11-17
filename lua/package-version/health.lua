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

---@param docker_config DockerConfig
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
	local config_validator = require("package-version.config")

	-- =============================================================================
	-- SECTION 1: Configuration Validation
	-- =============================================================================
	vim.health.start("Configuration Validation")

	if not plugin.config or vim.tbl_isempty(plugin.config) then
		vim.health.info("Using default configuration")
	else
		local ok, result_or_err = config_validator.validate(plugin.config)
		if ok then
			vim.health.ok("Configuration is valid")

			-- Show current spinner type
			if plugin.config.spinner and plugin.config.spinner.type then
				vim.health.info("Spinner type: " .. plugin.config.spinner.type)
			end

			-- Show timeout configuration
			if plugin.config.timeout then
				vim.health.info(string.format("Command timeout: %d seconds", plugin.config.timeout))
			else
				vim.health.info("Command timeout: 60 seconds (default)")
			end

			-- Show color configuration
			if plugin.config.color then
				vim.health.info("Color configuration:")
				if plugin.config.color.current then
					vim.health.info(string.format("  current: %s", plugin.config.color.current))
				end
				if plugin.config.color.latest then
					vim.health.info(string.format("  latest: %s", plugin.config.color.latest))
				end
				if plugin.config.color.wanted then
					vim.health.info(string.format("  wanted: %s", plugin.config.color.wanted))
				end
				if plugin.config.color.abandoned then
					vim.health.info(string.format("  abandoned: %s", plugin.config.color.abandoned))
				end
			end

			-- Show docker configuration status
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
		else
			---@cast result_or_err string
			vim.health.error("Configuration validation failed: " .. result_or_err)
			vim.health.info("Using default configuration as fallback")
		end
	end

	-- =============================================================================
	-- SECTION 2: Package Manager Availability
	-- =============================================================================
	vim.health.start("Package Manager Availability")

	local has_docker = vim.fn.executable("docker") == 1
	local docker_config = plugin.config.docker
	local has_docker_config = docker_config ~= nil

	-- CRITICAL VALIDATION: Docker config set but docker not installed
	if has_docker_config and not has_docker then
		vim.health.error("Docker configuration is set but docker executable not found", {
			"Install Docker: https://docs.docker.com/get-docker/",
			"Or remove docker configuration from setup() to use local package managers",
		})
		return
	end

	-- DOCKER MODE: Docker config set and docker is installed
	if has_docker_config and has_docker then
		vim.health.ok("Docker mode: docker executable found")

		---@cast docker_config DockerConfig
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

	-- LOCAL MODE: No docker config - check local package managers
	vim.health.info("Local mode: checking for package managers in PATH")

	local manager_count = check_local_managers()

	-- CRITICAL VALIDATION: No docker config AND no local managers
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
