# Agent Guidelines for pkgpeek.nvim

## Build/Lint/Test

- **No test suite**: This is a Neovim plugin without automated tests
- **Manual testing**: Use `:checkhealth pkgpeek` to validate plugin functionality
- **Lua syntax**: Run `lua -l <file>` to check syntax (basic validation only)

## Code Style

### Module Structure

- Use `local M = {}` pattern for modules, return `M` at end
- Place all requires at top of file

### Imports

- Group requires: external first, then internal (`pkgpeek.*`)
- Example: `local common = require("pkgpeek.utils.common")`

### Types (LuaLS annotations)

- Use `---@` annotations extensively for types, params, and return values
- Define types in `lua/pkgpeek/types.lua` (e.g., `---@class PkgPeekValidatedConfig`)
- Mark optional fields with `?` (e.g., `---@field docker? DockerValidatedConfig`)
- Use `---@param`, `---@return`, `---@type` consistently

### Naming Conventions

- **Files/modules**: kebab-case (e.g., `in-memory-cache.lua`)
- **Functions**: snake_case (e.g., `validate_color_config`)
- **Variables**: snake_case (e.g., `is_operation_running`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `DEFAULT_CONFIG`)

### Error Handling

- Use `logger.error()`, `logger.warning()`, `logger.info()` from `utils/logger`
- Return boolean + error message pattern: `return false, "error message"`
- Use `pcall()` for Neovim API calls that might fail

### Formatting

- **Indentation**: Tabs (not spaces)
- **Line length**: Keep reasonable (~120 chars)
-
