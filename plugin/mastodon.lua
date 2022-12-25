vim.api.nvim_create_user_command("MastodonTootMessage", require("mastodon").toot_message, {})
vim.api.nvim_create_user_command("MastodonAddAccount", require("mastodon").add_account, {})
vim.api.nvim_create_user_command("MastodonSelectAccount", require("mastodon").select_account, {})
vim.api.nvim_create_user_command("MastodonLoadHomeTimeline", require("mastodon").fetch_home_timeline, {})
vim.api.nvim_create_user_command("MastodonLoadBookmarks", require("mastodon").fetch_bookmarks, {})
vim.api.nvim_create_user_command("MastodonLoadFavourites", require("mastodon").fetch_favourites, {})
vim.api.nvim_create_user_command("MastodonLoadReplies", require("mastodon").fetch_replies, {})
vim.api.nvim_create_user_command("MastodonReload", require("mastodon").reload_statuses, {})


local map = vim.api.nvim_set_keymap
local default_opts = { noremap = true, silent = true }

local augroup = vim.api.nvim_create_augroup('user_cmds', { clear = false })

vim.api.nvim_create_autocmd('FileType', {
  pattern = {'mastodon'},
  group = augroup,
  desc = 'Only works on Mastodon Buffers',
  callback = function(event)
    -- if keymap starts with `,m`,
    -- buffer-wide or system-wide commands should be called
    map('n', ',mr', ":lua require('mastodon').reload_statuses()<CR>", default_opts)

    -- If keymap starts with `,t`
    -- status-wide commands should be called
    map('n', ',tr', ":lua require('mastodon.actions').reply()<CR>", default_opts)
    map('n', ',tb', ":lua require('mastodon.actions').toggle_bookmark()<CR>", default_opts)
    map('n', ',tf', ":lua require('mastodon.actions').toggle_favourite()<CR>", default_opts)
    map('n', ',tB', ":lua require('mastodon.actions').toggle_boost()<CR>", default_opts)
    map('n', ',tv', ":lua require('mastodon.actions').print_verbose_information()<CR>", default_opts)
  end
})

map('n', ',mR', ":lua require('mastodon').fetch_replies()<CR>", default_opts)
map('n', ',mf', ":lua require('mastodon').fetch_favourites()<CR>", default_opts)
map('n', ',mb', ":lua require('mastodon').fetch_bookmarks()<CR>", default_opts)
map('n', ',mh', ":lua require('mastodon').fetch_home_timeline()<CR>", default_opts)
map('n', ',ms', ":lua require('mastodon').select_account()<CR>", default_opts)
