# 🔒 Package Version

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)]((http://www.lua.org))
[![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)]((https://neovim.io))
[![Composer](https://img.shields.io/badge/Composer-%232E7EEA.svg?style=for-the-badge&logo=composer&logoColor=white)](https://getcomposer.org/)
[![NPM](https://img.shields.io/badge/NPM-%23CB3837.svg?style=for-the-badge&logo=npm&logoColor=white)](https://www.npmjs.com/)

This plugin will provide a better visibility of installed packages
without leaving main package file eg. `composer.json`, `package.json` etc...

An idea is to simplify the workflow and to reduce context switching
for developers who frequently manage packages by providing immediate visibility
of installed package version directly within the main package file.

![Package version](/images/package-version.gif)

## 📦 Installation

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

### Composer

```vim
:ComposerPackageVersionToggle
```

### NPM

```vim
:NpmPackageVersionToggle

```

> [!IMPORTANT]  
> It's important to note that this command can be executed only
> within dedicated file.
> For Composer inside `composer.json`, and for NPM inside `package.json`

## ⌨️ Mappings

If you already using `which-key`, you can use default keybinding
provided by plugin.

- `<leader>vc` - for Composer
- `<leader>vn` - for NPM

> [!IMPORTANT]
> If you are not using `which-key`, you can set keybindings to your preference eg.
>
> ```lua
> {
>    "nemanjajojic/package-version.nvim",
>    cmd = { "ComposerPackageVersionToggle", "NpmPackageVersionToggle" },
>    config = function()
>      require("package-version").setup()
>    end,
>    keys = {
>        -- Here you can set your preferred keybinding eg.
>        { 
>            "<leader>ComposerToggleKey",
>            "<cmd>ComposerPackageVersionToggle<cr>",
>            mode = "n", 
>            desc = "Toggle installed composer package version" 
>        },
>        { 
>            "<leader>NpmToggleKey",
>            "<cmd>NpmPackageVersionToggle<cr>",
>            mode = "n", 
>            desc = "Toggle installed NPM package version" 
>        },
>    }
>}
>```

## 🛠️ Configuration

You don’t have to change anything, but if you want to,
you can customize it to your liking.

```lua
config = function()
    require("package-version").setup({
        color = 'your color', --- default is 'Comment'
        icon = 'your icon', --- default is ''
    })
end

```

## ✨ Next Steps

Go checkout [TODO.md](TODO.md)
