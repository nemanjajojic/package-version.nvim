local M = {}
local command = require("package-version.command")

function M.setup()
	command.composer_packge_version_command()
end

return M
