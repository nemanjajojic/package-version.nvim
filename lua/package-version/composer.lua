local M = {}

local file = require("package-version.file")

local composer_json = "composer.json"
local composer_lock = "composer.lock"

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

M.show_package_version_virtual_text = function()
	if vim.fn.expand("%:t") ~= composer_json then
		vim.notify("This command can only be used inside of " .. composer_json .. " file", vim.log.levels.ERROR)

		return
	end

	local namespace_id = vim.api.nvim_create_namespace("Composer Virtual Text")

	if is_virtual_line_visible then
		vim.api.nvim_buf_clear_namespace(0, namespace_id, 0, -1)

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
