local M = {
	---@type PackageVersionConfig
	config = {},
}
local command = require("package-version.command")
local which_key_keymaps = require("package-version.which-key-keymaps")

---@param config? PackageVersionConfig
function M.setup(config)
	M.config = config or nil

	local success, whichkey = pcall(require, "which-key")

	if success and whichkey then
		which_key_keymaps.register_which_keys(config)
	end

	command.register_commands(config)
end

return M
