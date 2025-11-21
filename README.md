# 📦 Package Version

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)]((http://www.lua.org))
[![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)]((https://neovim.io))

## Supported Package Managers

[![Composer](https://img.shields.io/badge/Composer-%232E7EEA.svg?style=for-the-badge&logo=composer&logoColor=white)](https://getcomposer.org/)
[![NPM](https://img.shields.io/badge/NPM-%23CB3837.svg?style=for-the-badge&logo=npm&logoColor=white)](https://www.npmjs.com/)
[![Yarn](https://img.shields.io/badge/yarn-%232C8EBB.svg?style=for-the-badge&logo=yarn&logoColor=white)](https://yarnpkg.com/)
[![PNPM](https://img.shields.io/badge/pnpm-%234a4a4a.svg?style=for-the-badge&logo=pnpm&logoColor=f69220)](https://pnpm.io)

## 📋 Requirements

- **Neovim:** 0.10.0 or higher
- **Package Manager:** At least one of the following installed:
- npm (Node.js)
  - yarn
  - pnpm
- Composer (PHP)
- **Optional:** Docker (for containerized package management)

## The Problem

Imagine this: you’re in Neovim, and you want to keep an eye on your
installed, outdated, abandoned packages, or you wanna quickly update, remove or add them without
having to leave the editor in a single keystroke. Well, now you can! With this plugin,
you can toggle package versions right inside your main package manager file.

![Package version](/images/package-version.gif)

## ⚙️ Installation

Install plugin using package manager of your choice, for example with

### lazy.nvim

```lua
{
    "nemanjajojic/package-version.nvim",
    dependencies = { "folke/which-key.nvim" }, --- this is an optional dependency
    config = function()
      require("package-version").setup()
    end
}
```

## 💻 Commands

You have the following commands available:

### Package Information

- `:PackageVersionInstalled` - toggle installed package version
- `:PackageVersionOutdated` - toggle outdated package version
- `:PackageVersionHomepage` - open package homepage or repository in browser

### Package Updates

- `:PackageVersionUpdateAll` - update all outdated packages to latest version according to semver range
- `:PackageVersionUpdateSingle` - update single package to latest version according to semver range

> [!NOTE]
> **Composer users:** When running update commands, you'll be prompted to choose an update scope:
>
> - **Latest** - Updates to the latest version within semver constraints (default behavior)
> - **Patch** - Only allows patch version updates (e.g., 2.9.1 → 2.9.3, but not 2.9.1 → 2.10.0)
>
> This feature uses Composer's `--patch-only` flag and is only available for Composer. Other package managers (npm, yarn, pnpm) will update directly without prompting.

### Package Management

- `:PackageVersionInstall` - install packages from lock file
- `:PackageVersionRemove` - remove package under cursor from dependencies
- `:PackageVersionAddNew` - add a new package (prompts for dependency type and package name)

> [!IMPORTANT]
> `PackageVersionUpdateSingle` command will try to update package under cursor
>
> **`PackageVersionRemove` command:**
>
> - Removes the package under cursor from your dependencies
> - **Composer only:** Prompts to select dependency type (Production or Development) before removal
> - **npm/yarn/pnpm:** Automatically detects and removes from the correct section (no prompt needed)
> - If removal fails (e.g., due to dependency conflicts), an error window will display the detailed error message
>
> **`PackageVersionAddNew` command** uses a two-step flow:
>
> 1. **Select dependency type** - Choose between Production or Development dependencies
> 2. **Enter package name** - Specify which package to install
>
> If installation fails, an error window displays the detailed error message.
>
> `PackageVersionHomepage` command will try to open the homepage URL for the package under cursor. If homepage is not available, it falls back to the repository URL (if browser-friendly).

### Cache Management

- `:PackageVersionClearCache` - clear all cached package data
- `:PackageVersionCacheStats` - show cache statistics (list of cache keys with expiration status)

For more visual examples of commands in action, go check [COMMANDS.md](COMMANDS.md)

## ⌨️ Mappings

If you already using `which-key`, you can use default keybinding
provided by plugin.

### Package Operations

- `<leader>vi` - toggle installed package version
- `<leader>vo` - toggle outdated package version
- `<leader>vh` - open package homepage/repository in browser
- `<leader>vu` - update all outdated packages according to semver range
- `<leader>vs` - update single package according to semver range
- `<leader>vI` - install packages from lock file
- `<leader>vr` - remove package under cursor
- `<leader>va` - add a new package

### Cache Management

- `<leader>vcc` - clear all cached package data
- `<leader>vcs` - show cache statistics

> [!IMPORTANT]
> If you are not using `which-key`, you can set keybindings to your preference eg.
>
> ```lua
> {
>    "nemanjajojic/package-version.nvim",
>    cmd = { "PackageVersionInstalled" },
>    config = function()
>      require("package-version").setup()
>    end,
>    keys = {
>        -- Here you can set your preferred keybinding eg.
>        { 
>            "<leader>key",
>            "<cmd>PackageVersionInstalled<cr>",
>            mode = "n", 
>            desc = "Toggle installed package version" 
>        },
>    }
>}
>
>```

## 🛠️ Configuration

You don’t have to change anything, but if you want to,
you can customize it to your liking.

```lua
config = function()
    require("package-version").setup({
        color = {
            latest = "",
            wanted = "",
            current = "",
            abandoned = "",
        },
        spinner = {
            type = "pacman" | "ball" | "space" | "minimal" | "dino"
        },
        -- Command timeout in seconds (default: 60, max: 300)
        timeout = 60
        cache = {
            -- Enable caching (default: true)
            enabled = true
            ttl = {
                -- Cache duration for installed packages in seconds (default: 300 / 5 minutes)
                installed = 300,
                -- Cache duration for outdated packages in seconds (default: 300 / 5 minutes)
                outdated = 300,
            },
            warmup = {
                -- Debounce warmup triggers in milliseconds (default: 500)
                debounce_ms = 500,
                ttl = {
                    -- Warmup cache duration for installed packages (default: 3600 / 1 hour)
                    -- Set to 0 to disable warmup for installed packages
                    installed = 3600,
                    -- Warmup cache duration for outdated packages (default: 3600 / 1 hour)
                    -- Set to 0 to disable warmup for outdated packages
                    outdated = 3600,
                },
                -- Enable warmup on code files (*.js, *.ts, *.php, etc.)
                -- Default: false (only triggers on package files)
                enable_code_files = false,
            }
        },
        docker = {
            composer_container_name = "your_composer_container_name",
            npm_container_name = "your_npm_container_name",
            yarn_container_name = "your_yarn_container_name",
            pnpm_container_name = "your_pnpm_container_name",
        }
    })
end

```

## Color options

In order to align plugin with color scheme of your choice,
you should should customize this config according to your preferences.

> [!NOTE]
> You can use **hexadecimal color codes** (e.g., `#FF5733`)
> or **Neovim highlight group names** (e.g., `Comment`, `String`, `Error`).
> Using **Neovim highlight group names** will be more adaptive to changing themes

**Examples:**

```lua
color = {
    latest = "#a6e3a1",      -- Hex color (catppuccin green)
    wanted = "#f9e2af",      -- Hex color (catppuccin yellow)
    current = "Comment",     -- Neovim highlight group
    abandoned = "ErrorMsg",  -- Neovim highlight group
}
```

- `latest`- latest version available
- `wanted` - latest available version that matches semver range
- `current` - currently installed version
- `abandoned` - abandoned or deprecated package

### Spinner options

Some of command can take more time to execute, so spinner is added
to provide better user experience, while background task is running.

> [!NOTE]
> `space` is default spinner type.

You have couple of options to choose from. Please check [SPINNERS.md](SPINNERS.md)

### Timeout options

All commands (installed, outdated, update) have a built-in timeout protection
to prevent hung operations.

- **Default:** 60 seconds
- **Range:** 1 - 300 seconds (5 minutes max)
- **Behavior:** If a command exceeds the timeout, it will be automatically
stopped and an error message will be shown

**Example:**

```lua
require("package-version").setup({
    timeout = 60,
})
```

> [!NOTE]
> If you have a lot of private packages or slow network connections,
> you may want to increase the timeout value.

### Cache options

The plugin includes caching system to improve performance and
reduce unnecessary package manager calls.

- **Default:** Enabled with 5 minute TTL
- **TTL Range:** 0 - 3600 seconds (1 hour max)

**Example:**

```lua
require("package-version").setup({
    cache = {
        enabled = true,  -- Enable/disable caching system
        ttl = {
            installed = 300,  -- Cache installed packages for 5 minutes
            outdated = 300,   -- Cache outdated packages for 5 minutes
        }
    }
})
```

> [!TIP]
>
> - Set `ttl = 0` to disable caching for specific operations

> [!NOTE]
> If you frequently update packages outside of Neovim, you may want to
> reduce the TTL value or disable caching to ensure fresh data.

### Cache Warmup

The plugin includes an automatic cache warmup feature that pre-populates the cache
when you open package files. This provides **instant results** when you run commands,
without the wait!

**Warmup Triggers (by default):**

- Package manifests: `package.json`, `composer.json`
- Lock files: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `composer.lock`

**Optional: Warmup on Code Files**

You can enable warmup triggers on code files (`.js`, `.jsx`, `.ts`, `.tsx`, `.mjs`, `.cjs`, `.php`)
by setting `cache.warmup.enable_code_files = true`. This is **opt-in** because it's more
aggressive and may not be needed for all workflows.

> [!NOTE]
> When `enable_code_files = true`, the debounce time is automatically increased to a minimum of
> **5 seconds** (regardless of `debounce_ms` setting) to prevent excessive warmup triggers when
> rapidly switching between code files.

> [!TIP]
> **Warmup respects the main `cache.enabled` flag.** If caching is disabled, warmup will not run.
> To disable only warmup (keeping manual cache), set the warmup TTL values to 0.

**Example**

```lua
require("package-version").setup({
    cache = {
        warmup = {
            debounce_ms = 500,  -- Wait time before triggering warmup (default: 500)
                                -- Note: Automatically increased to 5000ms when enable_code_files = true
            ttl = {
                installed = 3600, -- Warmup cache duration (default: 3600 / 1 hour), set to 0 to disable
                outdated = 3600,  -- Warmup cache duration (default: 3600 / 1 hour), set to 0 to disable
            },
            enable_code_files = false,  -- Enable warmup on *.js, *.ts, *.php, etc. (default: false)
        }
    }
})
```

**Warmup TTL Settings:**

- **Range:** 0 - 86400 seconds (24 hours max)
- **Default:** 3600 seconds (1 hour)
- **Set to 0 to disable warmup**

> [!TIP]
> The warmup TTL is separate from manual command TTL. User commands always fetch fresh data
> (5 min cache), while warmup uses a longer cache (1 hour) to minimize API calls.

### Docker and local environment

Plugin support both local and docker environment. You have full control to
decide which one you wanna use.

#### Docker

In case you are using docker environment,
you have to set proper container name for each package manager.

- `composer_container_name` - in case you wanna use composer
- `npm_container_name` - in case you wanna use npm
- `yarn_container_name` - in case you wanna use yarn
- `pnpm_container_name` - in case you wanna use pnpm

#### Local

In case you wanna use local installation of package manager,
`docker` should not be set inside of a config.

> [!IMPORTANT]
> All package managers must be installed and available in your system `PATH`.

## 🩺 Health Check

Run `:checkhealth package-version` command to check if plugin is properly
configured and have everything need to work properly.

The health check validates:

- **Configuration** - Verifies your setup configuration is valid
- **Package Manager Availability** - Ensures required package managers or Docker are available

### Common Health Check Scenarios

**Docker Mode:**

- If you configure `docker` option, Docker must be installed on your system
- At least one container must be configured
- ❌ ERROR if docker config is set but docker is not installed

**Local Mode:**

- If no `docker` option is configured, at least one package manager must be in your PATH
- ❌ ERROR if no docker config AND no local package managers are found
- ✅ OK if at least one package manager (composer, npm, pnpm, or yarn) is available

## 🙏 Honorable Mentions

- [Nerd Fonts](https://www.nerdfonts.com/) -  for providing awesome icons
- [jellydn](https://github.com/jellydn/spinner.nvim) - for providing base spinner functionality
- [ileriayo](https://github.com/Ileriayo/markdown-badges) - for providing markdown badges

## ✨ Next Steps

Go checkout [TODO.md](TODO.md)

## ⭐️ Support

If you find this plugin helpful, please consider giving it a star
