# 🔒 Package Version

This plugin will help you to manage package version by showing installed version
from `composer.lock` inside of `composer.json`.

![Package version](/images/package-version.gif)

## 📦 Installation

Install plugin using package manager of your choice, for example with

### lazy.nvim

```lua
{
    "nemanjajojic/package-version.nvim",
     dependencies = {
      "folke/which-key.nvim",
    },
    config = function()
      require("package-version").setup()
    end,
    keys = {
        -- Here you can set your preferred keybinding
        {
            "<leader>C",
            function()
                require("package-version.composer").show_package_version_virtual_text()
            end,
            desc = "Show Composer Package Version",
        },
    }

}
```

## ⌨️ Mappings

Default keybinding to show installed package version is `<leader>pv`. However,
you can customize it to your liking in the installation section above.

> [!IMPORTANT]  
> It's important to note that this keybinding is only active
> when `composer.json` is open in current buffer.

## 💡 Idea

An idea is to simplify the workflow for developers who frequently work with
PHP projects by providing immediate visibility of installed package versions directly
within the `composer.json` file.

Apart from enhancing productivity, this feature aims to reduce
context switching between files.

> [!NOTE]
> This plugin draws inspiration from JetBrains PhpStorm IDE’s feature
> that displays installed package versions when the `composer.json` file is open.

## ✨ Next Steps

Plan is to support more package managers in the future:

- npm
- pip

## 👨‍💻 Author

[nemanjajojic](https://github.com/nemanjajojic)

## © License

This software is released under the MIT License.
