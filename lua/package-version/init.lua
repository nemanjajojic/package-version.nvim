local M = {}
local command = require("package-version.command")
local which_key_keymaps = require("package-version.which-key-keymaps")

function M.setup()
	local success, whichkey = pcall(require, "which-key")

	if success and whichkey then
		which_key_keymaps.register_which_keys()
	end

	command.packge_version_command()
end

return M
