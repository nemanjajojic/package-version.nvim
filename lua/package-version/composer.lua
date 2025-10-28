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

local is_virtual_line_visible = false

local function get_all_packages()
	local all_packages = {}
	local decoded_composer_lock_json = file.get_decoded_json_file(composer_lock)

	if not decoded_composer_lock_json then
		return all_packages
	end

	for _, package in pairs(decoded_composer_lock_json[packages_key]) do
		all_packages[package[package_name_key]] = package[version_key]
	end

	for _, package in pairs(decoded_composer_lock_json[packages_dev_key]) do
		all_packages[package[package_name_key]] = package[version_key]
	end

	return all_packages
end

M.show_package_version_floaty_window = function()
	if not file.has_file(composer_json) then
		vim.notify(composer_json .. " does not exist in current project root", vim.log.levels.ERROR)

		return
	end

	local decoded_composer_lock_json = file.get_decoded_json_file(composer_lock)

	if not decoded_composer_lock_json then
		return
	end

	local required_mapping = {}
	for _, required_package in pairs(decoded_composer_lock_json[packages_key]) do
		required_mapping[required_package[package_name_key]] = required_package[version_key]
	end

	local required_dev_mapping = {}
	for _, dev_package in pairs(decoded_composer_lock_json[packages_dev_key]) do
		required_dev_mapping[dev_package[package_name_key]] = dev_package[version_key]
	end

	local decoded_composer_json = file.get_decoded_json_file(composer_json)

	if not decoded_composer_json then
		return
	end

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

M.show_package_version_virtual_text = function()
	if vim.fn.expand("%:t") ~= composer_json then
		vim.notify("This command can only be used inside of " .. composer_json .. " file", vim.log.levels.ERROR)

		return
	end

	local namespace_id = vim.api.nvim_create_namespace("Composer Virtual Text")

	if is_virtual_line_visible then
		vim.api.nvim_buf_names(0, namespace_id, 0, -1)

		is_virtual_line_visible = false

		return
	end

	for package_name, package_version in pairs(get_all_packages()) do
		local line_number = file.does_buffer_contain_string(package_name)

		if line_number then
			vim.api.nvim_buf_set_extmark(0, namespace_id, line_number - 1, 0, {
				virt_text = { { "  " .. package_version, "Comment" } },
				virt_text_pos = "eol",
			})
		end
	end

	is_virtual_line_visible = true
end

return M
