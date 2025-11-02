# 🔒 Package Version

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
>    cmd = { "ComposerPackageVersionToggle", "NpmPackageVersionToggole" },
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

## ✨ Next Steps

Plan is to support more package managers in the future:

- Composer ✅
- npm ✅
- yarn v1
- pip

## 👨‍💻 Author

[nemanjajojic](https://github.com/nemanjajojic)

## © License

This software is released under the MIT License.
