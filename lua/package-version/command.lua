local M = {}

local strategy = require("package-version.package-manager.strategy")

---@param name string
---@param callback function
---@param description string
local create_command = function(name, callback, description)
	vim.api.nvim_create_user_command(name, callback, {
		bang = false,
		nargs = 0,
		desc = description,
	})
end

---@param config? PackageVersionConfig
M.register_commands = function(config)
	create_command("PackageVersionInstalled", function()
		strategy.installed(config)
	end, "Toggle instaled package version")

	create_command("PackageVersionOutdated", function()
		strategy.outdated(config)
	end, "Togglge outdated package version")

	create_command("PackageVersionUpdateAll", function()
		strategy.update_all(config)
	end, "Update all packages")

	create_command("PackageVersionUpdateOne", function()
		strategy.update_single(config)
	end, "Update singgle packages")
end

-- M.register_autocmds = function()
-- 	vim.api.nvim_create_augroup("InstlledGroup", { clear = true })
--
-- 	vim.api.nvim_create_autocmd({ "BufReadPost" }, {
-- 		group = "InstlledGroup",
-- 		pattern = "composer.json",
-- 		callback = function()
-- 			vim.api.nvim_command("PackageVersionInstalled")
-- 			vim.api.nvim_command("PackageVersionInstalled")
-- 		end,
-- 	})
-- end
return M
