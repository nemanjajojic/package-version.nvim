local M = {}

M.COMPOSER_JSON = "composer.json"
M.PACKAGE_JSON = "package.json"
M.COMPOSER_LOCK = "composer.lock"
M.PACKAGE_LOCK_JSON = "package-lock.json"
M.YARN_LOCK = "yarn.lock"
M.PNPM_LOCK_YAML = "pnpm-lock.yaml"

M.PACKAGE_MANAGER = {
	COMPOSER = "composer",
	NPM = "npm",
	YARN = "yarn",
	PNPM = "pnpm",
}

M.CODE_FILE_PATTERNS = {
	"*.js",
	"*.jsx",
	"*.ts",
	"*.tsx",
	"*.mjs",
	"*.cjs",
	"*.php",
}

-- ============================================================================
-- DEFAULT CONFIGURATION VALUES
-- ============================================================================
M.DEFAULT_VALUES = {
	TIMEOUT = 60,

	COLOR_LATEST = "#a6e3a1",
	COLOR_WANTED = "#f9e2af",
	COLOR_CURRENT = "Comment",
	COLOR_ABANDONED = "#eba0ac",

	SPINNER_TYPE = "space",

	CACHE_TTL_INSTALLED = 300,
	CACHE_TTL_OUTDATED = 300,

	WARMUP_DEBOUNCE_MS = 500,
	WARMUP_TTL_INSTALLED = 3600,
	WARMUP_TTL_OUTDATED = 3600,
	WARMUP_ENABLE_CODE_FILES = false,
}

-- ============================================================================
-- VALIDATION LIMITS
-- ============================================================================
M.LIMITS = {
	TIMEOUT_MIN = 1,
	TIMEOUT_MAX = 300,

	CACHE_TTL_MIN = 0,
	CACHE_TTL_MAX = 3600,

	WARMUP_DEBOUNCE_MIN = 0,
	WARMUP_DEBOUNCE_MAX = 10000,
	WARMUP_DEBOUNCE_CODE_FILES_MIN = 5000,

	WARMUP_TTL_MIN = 0,
	WARMUP_TTL_MAX = 86400,
}

-- ============================================================================
-- VALID SPINNER TYPES
-- ============================================================================
M.VALID_SPINNER_TYPES = {
	"pacman",
	"ball",
	"space",
	"minimal",
	"dino",
}

return M
