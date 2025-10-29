local M = {}
local keymaps = require("package-version.keymaps")

function M.setup()
	keymaps.register_which_keys()
end

return M
