local M = {}

local plugin = require("package-version")

local count_of_available_managers = 0
local count_of_containers = 0

local executable_managers = function()
	if vim.fn.executable("composer") == 1 then
		vim.health.ok("Local Composer is found.")

		count_of_available_managers = count_of_available_managers + 1
	else
		vim.health.warn(
			"Local Composer is not found in your system PATH.",
			"In case you are not using Composer, or using it via docker, you can ignore this warning"
		)
	end

	if vim.fn.executable("npm") == 1 then
		vim.health.ok("Local Npm is found.")

		count_of_available_managers = count_of_available_managers + 1
	else
		vim.health.warn(
			"Local Npm is not found in your system PATH.",
			"In case you are not using Npm, or using it via docker, you can ignore this warning"
		)
	end

	if vim.fn.executable("pnpm") == 1 then
		vim.health.ok("Local Pnpm is found.")

		count_of_available_managers = count_of_available_managers + 1
	else
		vim.health.warn(
			"Local Pnpm is not found in your system PATH.",
			"In case you are not using Pnpm, or using it via docker, you can ignore this warning"
		)
	end

	if vim.fn.executable("yarn") == 1 then
		vim.health.ok("Local Yarn is found.")

		count_of_available_managers = count_of_available_managers + 1
	else
		vim.health.warn(
			"Local Yarn is not found in your system PATH.",
			"In case you are not using Yarn, or using it via docker, you can ignore this warning"
		)
	end

	if count_of_available_managers == 0 then
		vim.health.error("No package managers found locally", {
			"You have to install at least one of the supported package managers: Composer, Npm, Pnpm, Yarn.",
			"Or you can use via docker by setting up the docker configuration.",
		})
	else
		vim.health.ok("Plugin can use local package manager")
	end
end

function M.check()
	vim.health.start("Plugin Version")

	vim.health.info("Depends on on your project you'll not have to have all package managers.")

	if vim.fn.executable("docker") == 1 then
		vim.health.ok("Docker is installed.")

		local docker = plugin.config.docker

		if not docker then
			vim.health.warn(
				"Docker configuration is not set.",
				"In case you have plugin manager installed locally you can ignore this warning"
			)

			executable_managers()
		else
			if docker.composer_container_name and docker.composer_container_name ~= "" then
				vim.health.ok("Composer Docker container name is set")

				count_of_containers = count_of_containers + 1
			else
				vim.health.warn(
					"Composer Docker container name is not set.",
					"If you are not using composer, or you are using locally, you can ignore this warning"
				)
			end

			if docker.npm_container_name and docker.npm_container_name ~= "" then
				vim.health.ok("Npm Docker container name is set")

				count_of_containers = count_of_containers + 1
			else
				vim.health.warn(
					"Npm Docker container name is not set.",
					"If you are not using npm, or you are using locally, you can ignore this warning"
				)
			end

			if docker.pnpm_container_name and docker.pnpm_container_name ~= "" then
				vim.health.ok("Pnpm Docker container name is set")

				count_of_containers = count_of_containers + 1
			else
				vim.health.warn(
					"Pnpm Docker container name is not set.",
					"If you are not using pnpm, or you are using locally, you can ignore this warning"
				)
			end

			if docker.yarn_container_name and docker.yarn_container_name ~= "" then
				vim.health.ok("Yarn Docker container name is set")

				count_of_containers = count_of_containers + 1
			else
				vim.health.warn(
					"Yarn Docker container name is not set.",
					"If you are not using yarn, or you are using locally, you can ignore this warning"
				)
			end

			if count_of_containers == 0 then
				vim.health.error("Docker config is detected without any container set.", {
					"You have to set at least one of the supported package manager container names: composer_container_name, npm_container_name, pnpm_container_name, yarn_container_name",
					"In case you wanna use from local, you have to remove docker config entirely",
				})

				executable_managers()

				return
			else
				vim.health.ok("Plugin can use package manager Docker containers")
			end

			executable_managers()

			return
		end
	else
		executable_managers()

		return
	end
end

return M
