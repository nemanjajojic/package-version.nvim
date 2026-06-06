local M = {
	config = {},
}
local command = require("pkgpeek.command")
local which_key_keymaps = require("pkgpeek.which-key")
local config_validator = require("pkgpeek.utils.config")
local cache = require("pkgpeek.cache")

---@param config? PkgPeekUserConfig
function M.setup(config)
	local ok, result = config_validator.validate(config)

	---@type PkgPeekValidatedConfig
	local validated_config
	if ok then
		---@cast result PkgPeekValidatedConfig
		validated_config = result
	else
		validated_config = config_validator.DEFAULT_CONFIG
	end

	M.config = validated_config

	local success, whichkey = pcall(require, "which-key")

	if success and whichkey then
		which_key_keymaps.register_which_keys(validated_config)
	end

	command.register_commands(validated_config)

	cache.run_warmup(validated_config)
end

return M
