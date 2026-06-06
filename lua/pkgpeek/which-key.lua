local M = {}

---@param config PkgPeekValidatedConfig
M.register_which_keys = function(config)
	local which_key = require("which-key")

	which_key.add({
		{
			"<leader>p",
			group = "pkgpeek",
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
		},
		{
			"<leader>pi",
			function()
				require("pkgpeek.strategy").installed(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Toggle installed package versions",
		},
		{
			"<leader>pI",
			function()
				require("pkgpeek.strategy").install(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Install packages from lock file",
		},
		{
			"<leader>po",
			function()
				require("pkgpeek.strategy").outdated(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Toggle outdated package versions",
		},
		{
			"<leader>ph",
			function()
				require("pkgpeek.strategy").homepage(config)
			end,
			icon = {
				icon = "󰋜 ",
				color = "blue",
			},
			desc = "Open package homepage/repository in browser",
		},
		{
			"<leader>pu",
			function()
				require("pkgpeek.strategy").update_all(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Update all packages",
		},
		{
			"<leader>ps",
			function()
				require("pkgpeek.strategy").update_single(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Update package under cursor",
		},
		{
			"<leader>pr",
			function()
				require("pkgpeek.strategy").remove(config)
			end,
			icon = {
				icon = "󱧙 ",
				color = "red",
			},
			desc = "Remove package under cursor",
		},
		{
			"<leader>pa",
			function()
				require("pkgpeek.strategy").add_new(config)
			end,
			icon = {
				icon = "󰏖 ",
				color = "green",
			},
			desc = "Add new package",
		},
		{
			"<leader>pb",
			function()
				require("pkgpeek.strategy").bump(config)
			end,
			icon = {
				icon = " ",
				color = "green",
			},
			desc = "Bump versions (Composer only)",
		},
		{
			"<leader>pA",
			function()
				require("pkgpeek.strategy").audit(config)
			end,
			icon = {
				icon = "󰒃 ",
				color = "green",
			},
			desc = "Audit package vulnerabilities",
		},
		{
			"<leader>pc",
			group = "Cache",
			icon = {
				icon = " ",
				color = "yellow",
			},
		},
		{
			"<leader>pcc",
			function()
				require("pkgpeek.cache").clear_all()
			end,
			icon = {
				icon = " ",
				color = "red",
			},
			desc = "Clear plugin cache",
		},
		{
			"<leader>pcs",
			function()
				require("pkgpeek.cache").stats()
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
