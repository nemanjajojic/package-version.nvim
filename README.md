# 📦 Package Version

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)]((http://www.lua.org))
[![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)]((https://neovim.io))
[![Composer](https://img.shields.io/badge/Composer-%232E7EEA.svg?style=for-the-badge&logo=composer&logoColor=white)](https://getcomposer.org/)
[![NPM](https://img.shields.io/badge/NPM-%23CB3837.svg?style=for-the-badge&logo=npm&logoColor=white)](https://www.npmjs.com/)

An idea of this plugin is to simplify the workflow and to reduce context switching
for developers who frequently manage packages by providing immediate visibility
of installed(current) and outdated and abandoned packages
directly within the main package file.

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

Plugin supports following package managers:

- Composer
- NPM

## 💻 Commands

You have two commands available:

- `:PackageVersionInstalled`
- `:PackageVersionOutdated`

## ⌨️ Mappings

If you already using `which-key`, you can use default keybinding
provided by plugin.

- `<leader>vi` - installed package version
- `<leader>vo` - outdated package version

> [!IMPORTANT]
> If you are not using `which-key`, you can set keybindings to your preference eg.
>
> ```lua
> {
>    "nemanjajojic/package-version.nvim",
>    cmd = { "PackageVersionInstalled","PackageVersionOutdated" },
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
>        {
>            "<leader>key",
>            "<cmd>PackageVersionOutdated<cr>",
>            mode = "n", 
>            desc = "Toggle outdated package version" 
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
            major = "",
            minor = "",
            current = "",
            up_to_date = "",
            abandoned = "",
        },
        spinner = {
            type = "pacman" | "ball" | "space" | "minimal" | "dino"
        },
        docker = {
            composer_container_name = "your_composer_container_name",
            npm_container_name = "your_npm_container_name",
        }
    })
end

```

## Color options

In order to align plugin with color scheme of your choice,
you should should customize this config according to your preferences.

> [!NOTE]
> You can use hexadecimal color codes eg. `#FF5733`

- `major` - color for major version updates eg. from v1.0.0 to v2.0.0
- `minor` - color for minor version updates eg. from v1.0.0 to v1.1.0
- `current` - color for current installed version
- `up_to_date` - color for up to date packages eg. package is already on latest version
- `abandoned` - color for abandoned packages eg. package is no longer maintained

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

#### Local

In case you wanna use local installation of package manager,
`docker` should not be set inside of a config.

> [!IMPORTANT]
> All package managers must be installed and available in your system `PATH`.

## 🙏 Honorable Mentions

- [Nerd Fonts](https://www.nerdfonts.com/) -  for providing awesome icons
- [jellydn](https://github.com/jellydn/spinner.nvim) - for providing base spinner functionality

## ✨ Next Steps

Go checkout [TODO.md](TODO.md)

## ⭐️ Support

If you find this plugin helpful, please consider giving it a star
