local M = {}

local strategy = require("package-version.strategy")

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
			group = "Installed",
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			function()
				strategy.installed(config)
			end,
			desc = "Toggle installed package versions from lock file",
		},
		{
			"<leader>vo",
			group = "Outdated",
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			function()
				strategy.outdated(config)
			end,
			desc = "Toggle outdated package versions",
		},
		{
			"<leader>vu",
			group = "Update All",
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			function()
				strategy.update_all(config)
			end,
			desc = "Update all packages to latest version",
		},
		{
			"<leader>vs",
			group = "Update Single",
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			function()
				strategy.update_single(config)
			end,
			desc = "Update single package to latest version",
		},
		{
			"<leader>vh",
			group = "Visit Package Homepage",
			function()
				strategy.homepage(config)
			end,
			icon = {
				icon = " ",
				color = "green",
			},
			desc = "Visit package homepage or github page",
		},
		{
			"<leader>vc",
			group = "Cache",
			icon = {
				icon = " ",
				color = "red",
			},
		},
		{
			"<leader>vcc",
			group = "Clear All",
			function()
				require("package-version.cache").clear_all()
			end,
			icon = {
				icon = " ",
				color = "red",
			},
			desc = "Clear all plugin cache",
		},
		{
			"<leader>vcs",
			group = "Stats",
			function()
				require("package-version.cache").stats()
			end,
			icon = {
				icon = " ",
				color = "green",
			},
			desc = "Display cache stats",
		},
	})
end

return M
