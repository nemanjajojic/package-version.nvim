local M = {}

local OS_LINUX = "Linux"
local OS_DARWIN = "Darwin"
local OS_WINDOWS = "Windows"

---Normalize a repository URL (git/ssh/scp) into a browser-safe https URL.
---Returns nil when the input cannot be converted to http(s).
---@param url string|nil
---@return string|nil https_url
M.normalize_repo_url = function(url)
	if type(url) ~= "string" or url == "" then
		return nil
	end

	url = vim.trim(url)

	if url == "" then
		return nil
	end

	-- Reject embedded control characters (CR/LF/NUL/etc). vim.trim only
	-- strips leading/trailing whitespace, so any control byte in the middle
	-- would survive. Legitimate URLs never contain raw control bytes; this
	-- closes a defense-in-depth gap against crafted source.url values.
	if url:find("%c") then
		return nil
	end

	-- Strip a single trailing ".git" suffix (e.g. ".../repo.git" -> ".../repo")
	url = url:gsub("%.git$", "")

	-- Already https — return as-is
	if url:match("^https://") then
		return url
	end

	-- Upgrade http -> https. We never want to hand a plaintext URL to the
	-- browser when we have the choice; all other branches below emit https.
	local http_rest = url:match("^http://(.+)$")
	if http_rest then
		return "https://" .. http_rest
	end

	-- git://host/path  ->  https://host/path
	local rest = url:match("^git://(.+)$")
	if rest then
		return "https://" .. rest
	end

	-- ssh://[user@]host[:port]/path  ->  https://host/path
	if url:match("^ssh://") then
		local body = url:gsub("^ssh://", "")
		body = body:gsub("^[^@/]+@", "")
		local host, path = body:match("^([^:/]+):?%d*/(.+)$")
		if host and path and host ~= "" and path ~= "" then
			return "https://" .. host .. "/" .. path
		end
		return nil
	end

	-- SCP form  user@host:org/repo  ->  https://host/org/repo
	local host, path = url:match("^[%w._-]+@([%w.%-]+):(.+)$")
	if host and path and path ~= "" then
		return "https://" .. host .. "/" .. path
	end

	return nil
end

---@param url string
M.open_url = function(url)
	local logger = require("package-version.utils.logger")
	local os_name = vim.uv.os_uname().sysname
	local cmd

	if os_name == OS_DARWIN then
		cmd = { "open", url }
	elseif os_name == OS_LINUX then
		cmd = { "xdg-open", url }
	elseif os_name:match(OS_WINDOWS) then
		-- Use rundll32 + url.dll FileProtocolHandler rather than `cmd /c start <url>`.
		-- `cmd.exe` re-parses its tail with its own metacharacter rules (&, |, ^, >, <, %VAR%)
		-- regardless of how libuv quotes argv, so any of those characters surviving in `url`
		-- becomes a command-injection vector on Windows (same class as Node.js CVE-2024-27980
		-- "BatBadBut"). url.dll's FileProtocolHandler hands the URL straight to the registered
		-- protocol handler without a shell re-parse.
		cmd = { "rundll32", "url.dll,FileProtocolHandler", url }
	else
		logger.error("Unsupported operating system: " .. os_name)
		return
	end

	vim.fn.jobstart(cmd, { detach = true })
end

return M
