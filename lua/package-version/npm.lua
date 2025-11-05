local M = {}

local file = require("package-version.file")
local virtual_text = require("package-version.virtual-text")

---@return table<string, string>
local function get_all_packages()
	local all_packages = {}
	local decoded_package_lock_json = file.get_decoded_json_file("package-lock.json")

	if not decoded_package_lock_json then
		return all_packages
	end

	for package_name, package in pairs(decoded_package_lock_json["packages"]) do
		local proccesed_name = string.gsub(package_name, "^node_modules/", "")
		all_packages[proccesed_name] = package.version
	end

	return all_packages
end

---@param config? PackageVersionConfig
M.toggle_package_version_virtual_text = function(config)
	virtual_text.toggle_package_version_virtual_text(get_all_packages(), "package.json", "NPM", config)
end

return M
