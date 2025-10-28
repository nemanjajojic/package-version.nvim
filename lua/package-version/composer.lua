local M = {}

local window = require("package-version.window")
local file = require("package-version.file")

local composer_json = "composer.json"
local composer_lock = "composer.lock"

local require_key = "require"
local require_dev_key = "require-dev"
local packages_key = "packages"
local packages_dev_key = "packages-dev"
local version_key = "version"
local package_name_key = "name"

M.show_package_version = function()
	if not file.has_file(composer_json) then
		vim.notify(composer_json .. " does not exist in current project root", vim.log.levels.ERROR)

		return
	end

	local decoded_composer_lock_json = file.get_decoded_json_file(composer_lock)

	local required_mapping = {}
	for _, required_package in pairs(decoded_composer_lock_json[packages_key]) do
		required_mapping[required_package[package_name_key]] = required_package[version_key]
	end

	local required_dev_mapping = {}
	for _, dev_package in pairs(decoded_composer_lock_json[packages_dev_key]) do
		required_dev_mapping[dev_package[package_name_key]] = dev_package[version_key]
	end

	local decoded_composer_json = file.get_decoded_json_file(composer_json)

	local required_packages_count = 0
	local required_packages_mapping = {}
	for package, _ in pairs(decoded_composer_json[require_key]) do
		if required_mapping[package] then
			required_packages_mapping[package] = required_mapping[package]
			required_packages_count = required_packages_count + 1
		end
	end

	local required_dev_count = 0
	local required_dev_packages_mapping = {}
	for package, _ in pairs(decoded_composer_json[require_dev_key]) do
		if required_dev_mapping[package] then
			required_dev_packages_mapping[package] = required_dev_mapping[package]
			required_dev_count = required_dev_count + 1
		end
	end

	local output_data = {}
	output_data["Info"] = {
		["Content Hash"] = decoded_composer_lock_json["content-hash"],
		["Count of required packages"] = required_packages_count,
		["Count of required-dev packages"] = required_dev_count,
	}
	output_data["Required_Packages"] = required_packages_mapping
	output_data["Required_Packages_Dev"] = required_dev_packages_mapping

	window.create_floating_window(output_data)
end

return M
