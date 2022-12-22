
# Mastodon Client for Neovim

![GitHub Workflow Status](https://img.shields.io/github/workflow/status/ellisonleao/nvim-plugin-template/default?style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

mastodon.nvim is Mastodon Client for Neovim.

## Requirements

* plenary.nvim
* nvim-notify

## Installation

If you are using packer.nvim, you can install this plugin as below:

```lua
use {
  "kode-team/mastodon.nvim",
  requires = {
    "nvim-lua/plenary.nvim",
    "rcarriga/nvim-notify",
  },
  config = function()
    require("mastodon").setup()
  end
}
```

## Usage


### (Important) Adding mastodon account

Before using this plugin, you need to add your mastodon account using `MastodonAddAccount` command. With this command, you can


### Loading Timeline

With `MastodonLoadHomeTimeline` command, you can see your account's home timeline.

### Switching to another account

If you want to switch to another account, you can use `MastodonSelectAccount` command


## Keymap

(WIP)

# Explanation for developers


## Project Structure

```sh
.
├── Makefile
├── README.md
├── lua
│   ├── mastodon
│   │   ├── actions.lua
│   │   ├── api_client.lua
│   │   ├── commands.lua
│   │   ├── db_client.lua
│   │   ├── parser.lua
│   │   ├── renderer.lua
│   │   └── utils.lua
│   └── mastodon.lua
```

## Testing

```sh
$ make
```

