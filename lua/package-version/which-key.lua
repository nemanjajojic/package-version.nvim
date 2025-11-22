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
			function()
				strategy.installed(config)
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
				strategy.install(config)
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
				strategy.outdated(config)
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
				strategy.homepage(config)
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
				strategy.update_all(config)
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
				strategy.update_single(config)
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
				strategy.remove(config)
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
				strategy.add_new(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Add new package",
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
