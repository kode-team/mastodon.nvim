vim.api.nvim_create_user_command("MyFirstFunction", require("mastodon").greeting, {})
vim.api.nvim_create_user_command("TootMessage", require("mastodon").toot_message, { nargs = 1 })
