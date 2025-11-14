# 📦 Package Version

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)]((http://www.lua.org))
[![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)]((https://neovim.io))

## Supported Package Managers

[![Composer](https://img.shields.io/badge/Composer-%232E7EEA.svg?style=for-the-badge&logo=composer&logoColor=white)](https://getcomposer.org/)
[![NPM](https://img.shields.io/badge/NPM-%23CB3837.svg?style=for-the-badge&logo=npm&logoColor=white)](https://www.npmjs.com/)
[![Yarn](https://img.shields.io/badge/yarn-%232C8EBB.svg?style=for-the-badge&logo=yarn&logoColor=white)](https://yarnpkg.com/)
[![PNPM](https://img.shields.io/badge/pnpm-%234a4a4a.svg?style=for-the-badge&logo=pnpm&logoColor=f69220)](https://pnpm.io)

## The Problem

Imagine this: you’re in Neovim, and you want to keep an eye on your
installed, outdated, abandoned packages, or you wanna quickly update them without
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

You have two commands available:

- `:PackageVersionInstalled` - toggle installed package version
- `:PackageVersionOutdated` - toggle outdated package version
- `:PackageVersionUpdateAll` - update all outdated packages to latest version according to semver range
- `:PackageVersionUpdateSingle` - update single package to latest version according to semver range.

> [!IMPORTANT]
> `PackageVersionUpdateSingle` command will try to update package under cursor

## ⌨️ Mappings

If you already using `which-key`, you can use default keybinding
provided by plugin.

- `<leader>vi` - toggle installed package version
- `<leader>vo` - toggle outdated package version
- `<leader>vu` - update all outdated packages according to semver range
- `<leader>vs` - update single package according to semver range

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
        docker = {
            composer_container_name = "your_composer_container_name",
            npm_container_name = "your_npm_container_name",
            npm_container_name = "your_npm_container_name",
            pnpm_container_name = "your_pnpm_container_name",
        }
    })
end

```

## Color options

In order to align plugin with color scheme of your choice,
you should should customize this config according to your preferences.

> [!NOTE]
> You can use hexadecimal color codes eg. `#FF5733`

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

## 🙏 Honorable Mentions

- [Nerd Fonts](https://www.nerdfonts.com/) -  for providing awesome icons
- [jellydn](https://github.com/jellydn/spinner.nvim) - for providing base spinner functionality
- [ileriayo](https://github.com/Ileriayo/markdown-badges) - for providing markdown badges

## ✨ Next Steps

Go checkout [TODO.md](TODO.md)

## ⭐️ Support

If you find this plugin helpful, please consider giving it a star
