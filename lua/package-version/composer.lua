local M = {}

M.show_package_version = function()
	if not Has_composer_json() then
		vim.notify("No composer.json found in current project root", vim.log.levels.ERROR)

		return
	end

	local decoded_composer_lock_json = Get_decoded_json_file("composer.lock")

	local required_mapping = {}
	for _, required_package in pairs(decoded_composer_lock_json.packages) do
		required_mapping[required_package.name] = required_package.version
	end

	local required_dev_mapping = {}
	for _, dev_package in pairs(decoded_composer_lock_json["packages-dev"]) do
		required_dev_mapping[dev_package.name] = dev_package.version
	end

	local decoded_composer_json = Get_decoded_json_file("composer.json")

	local required_packages_count = 0
	local required_packages_mapping = {}
	for package, _ in pairs(decoded_composer_json.require) do
		if required_mapping[package] then
			required_packages_mapping[package] = required_mapping[package]
			required_packages_count = required_packages_count + 1
		end
	end

	local required_dev_count = 0
	local required_dev_packages_mapping = {}
	for package, _ in pairs(decoded_composer_json["require-dev"]) do
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

	Create_floating_window(output_data)
end

function Get_decoded_json_file(file_name)
	local file_path = vim.fs.joinpath(vim.fn.getcwd(), file_name)
	local file_handle = io.open(file_path, "r")

	if not file_handle then
		vim.notify("Could not open " .. file_name .. ". File might not exist.", vim.log.levels.ERROR)
		return {}
	end

	local file_content = file_handle:read("*a")

	file_handle:close()

	return vim.json.decode(file_content)
end

function Has_composer_json()
	local composer_path = vim.fs.joinpath(vim.fn.getcwd(), "composer.json")
	local stat = (vim.uv or vim.loop).fs_stat(composer_path)

	return stat ~= nil and stat.type == "file"
end

function Create_floating_window(table)
	local buf = vim.api.nvim_create_buf(false, true)

	local screen_width = vim.api.nvim_win_get_width(0)
	local screen_height = vim.api.nvim_win_get_height(0)

	local width = 80
	local height = 20
	local row = (screen_height - height) / 2
	local col = (screen_width - width) / 2

	local opts = {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		border = "rounded",
		style = "minimal",
		focusable = true,
	}

	local win = vim.api.nvim_open_win(buf, true, opts)

	Write_table_to_buffer(buf, table)

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, false)
	end, { buffer = buf })
end

function Write_table_to_buffer(buffer, table)
	local output_str = vim.inspect(table)
	local lines = vim.split(output_str, "\n")

	vim.bo[buffer].modifiable = true

	vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)

	vim.bo[buffer].modifiable = false

	vim.bo[buffer].filetype = "lua"
end

return M
