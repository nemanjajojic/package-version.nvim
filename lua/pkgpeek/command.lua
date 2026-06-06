local M = {}

---@param config PkgPeekValidatedConfig
M.register_commands = function(config)
	local commands = {
		{ "installed",     function() require("pkgpeek.strategy").installed(config) end },
		{ "outdated",      function() require("pkgpeek.strategy").outdated(config) end },
		{ "update-all",    function() require("pkgpeek.strategy").update_all(config) end },
		{ "update-single", function() require("pkgpeek.strategy").update_single(config) end },
		{ "install",       function() require("pkgpeek.strategy").install(config) end },
		{ "homepage",      function() require("pkgpeek.strategy").homepage(config) end },
		{ "remove",        function() require("pkgpeek.strategy").remove(config) end },
		{ "add-new",       function() require("pkgpeek.strategy").add_new(config) end },
		{ "bump",          function() require("pkgpeek.strategy").bump(config) end },
		{ "clear-cache",   function() require("pkgpeek.cache").clear_all() end },
		{ "cache-stats",   function() require("pkgpeek.cache").stats() end },
		{ "audit",         function() require("pkgpeek.strategy").audit(config) end },
	}

	local handlers = {}
	local order = {}
	for _, c in ipairs(commands) do
		handlers[c[1]] = c[2]
		table.insert(order, c[1])
	end

	vim.api.nvim_create_user_command("PkgPeek", function(opts)
		local logger = require("pkgpeek.utils.logger")
		local verb = opts.fargs[1]

		if not verb then
			logger.error("Usage: :PkgPeek <command> (press <Tab> to see available verbs)")
			return
		end

		local handler = handlers[verb]

		if not handler then
			logger.error("Unknown :PkgPeek command '" .. verb .. "'")
			return
		end

		handler()
	end, {
		nargs = "?",
		desc = "pkgpeek subcommand dispatcher",
		complete = function(arg_lead)
			return vim.tbl_filter(function(v)
				return vim.startswith(v, arg_lead)
			end, order)
		end,
	})
end

return M
