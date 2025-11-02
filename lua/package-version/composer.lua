local M = {}

local file = require("package-version.file")
local virtual_text = require("package-version.virtual-text")

local function get_all_packages()
	local version_key = "version"
	local package_name_key = "name"

	local all_packages = {}
	local decoded_composer_lock_json = file.get_decoded_json_file("composer.lock")

	if not decoded_composer_lock_json then
		return all_packages
	end

	for _, package in pairs(decoded_composer_lock_json["packages"]) do
		all_packages[package[package_name_key]] = package[version_key]
	end

	for _, package in pairs(decoded_composer_lock_json["packages-dev"]) do
		all_packages[package[package_name_key]] = package[version_key]
	end

	return all_packages
end

M.toggle_package_version_virtual_text = function()
	virtual_text.toggle_package_version_virtual_text(get_all_packages(), "composer.json", "Composer")
end

return M
