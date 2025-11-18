-- ============================================================================
-- USER INPUT TYPES (Nullable - Before Validation)
-- ============================================================================

---@class PackageVersionUserConfig
---@field color? ColorUserConfig
---@field spinner? SpinnerUserConfig
---@field docker? DockerUserConfig
---@field timeout? number
---@field cache? CacheUserConfig

---@class ColorUserConfig
---@field wanted? string
---@field latest? string
---@field current? string
---@field abandoned? string

---@class SpinnerUserConfig
---@field type? "pacman" | "ball" | "space" | "minimal" | "dino"

---@class DockerUserConfig
---@field composer_container_name? string
---@field npm_container_name? string
---@field yarn_container_name? string
---@field pnpm_container_name? string

---@class CacheUserConfig
---@field enabled? boolean
---@field ttl? CacheTTLUserConfig
---@field warmup? WarmupUserConfig

---@class CacheTTLUserConfig
---@field installed? number
---@field outdated? number

---@class WarmupUserConfig
---@field debounce_ms? number
---@field ttl? WarmupTTLUserConfig

---@class WarmupTTLUserConfig
---@field installed? number
---@field outdated? number

-- ============================================================================
-- VALIDATED TYPES (Non-Nullable - After Validation)
-- ============================================================================

---@class PackageVersionValidatedConfig
---@field color ColorValidatedConfig
---@field spinner SpinnerValidatedConfig
---@field docker DockerValidatedConfig?
---@field timeout number
---@field cache CacheValidatedConfig

---@class ColorValidatedConfig
---@field wanted string
---@field latest string
---@field current string
---@field abandoned string

---@class SpinnerValidatedConfig
---@field type "pacman" | "ball" | "space" | "minimal" | "dino"

---@class DockerValidatedConfig
---@field composer_container_name? string
---@field npm_container_name? string
---@field yarn_container_name? string
---@field pnpm_container_name? string

---@class CacheValidatedConfig
---@field enabled boolean
---@field ttl CacheTTLValidatedConfig
---@field warmup WarmupValidatedConfig

---@class CacheTTLValidatedConfig
---@field installed number
---@field outdated number

---@class WarmupValidatedConfig
---@field debounce_ms number
---@field ttl WarmupTTLValidatedConfig

---@class WarmupTTLValidatedConfig
---@field installed number
---@field outdated number

-- ============================================================================
-- INTERNAL TYPES
-- ============================================================================

---@class CacheEntry
---@field data any
---@field timestamp number
---@field ttl number

---@class CacheStatsItems
---@field key string
---@field expired boolean

---@class CacheStats
---@field items CacheStatsItems[]

---@class TimeoutTimer
---@field stop fun()
---@field close fun()
