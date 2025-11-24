local M = {}

---@param config PackageVersionValidatedConfig
M.register_which_keys = function(config)
	local which_key = require("which-key")

	which_key.add({
		{
			"<leader>v",
			group = "package version",
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
		},
		{
			"<leader>vi",
			function()
				require("package-version.strategy").installed(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Toggle installed package versions",
		},
		{
			"<leader>vI",
			function()
				require("package-version.strategy").install(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Install packages from lock file",
		},
		{
			"<leader>vo",
			function()
				require("package-version.strategy").outdated(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Toggle outdated package versions",
		},
		{
			"<leader>vh",
			function()
				require("package-version.strategy").homepage(config)
			end,
			icon = {
				icon = "󰋜 ",
				color = "blue",
			},
			desc = "Open package homepage/repository in browser",
		},
		{
			"<leader>vu",
			function()
				require("package-version.strategy").update_all(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Update all packages",
		},
		{
			"<leader>vs",
			function()
				require("package-version.strategy").update_single(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Update package under cursor",
		},
		{
			"<leader>vr",
			function()
				require("package-version.strategy").remove(config)
			end,
			icon = {
				icon = "󱧙 ",
				color = "red",
			},
			desc = "Remove package under cursor",
		},
		{
			"<leader>va",
			function()
				require("package-version.strategy").add_new(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Add new package",
		},
		{
			"<leader>vA",
			function()
				require("package-version.strategy").audit(config)
			end,
			icon = {
				icon = "󰒃 ",
				color = "green",
			},
			desc = "Audit package vulnerabilities",
		},
		{
			"<leader>vc",
			group = "Cache",
			icon = {
				icon = " ",
				color = "yellow",
			},
		},
		{
			"<leader>vcc",
			function()
				require("package-version.cache").clear_all()
			end,
			icon = {
				icon = " ",
				color = "red",
			},
			desc = "Clear plugin cache",
		},
		{
			"<leader>vcs",
			function()
				require("package-version.cache").stats()
			end,
			icon = {
				icon = " ",
				color = "blue",
			},
			desc = "Display cache stats",
		},
	})
end

return M
