local M = {}

local strategy = require("package-version.package-manager.strategy")

---@param config? PackageVersionConfig
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
	})
end

return M
