vim.api.nvim_create_user_command("MastodonTootMessage", require("mastodon").toot_message, {})
vim.api.nvim_create_user_command("MastodonAddAccount", require("mastodon").add_account, {})
vim.api.nvim_create_user_command("MastodonSelectAccount", require("mastodon").select_account, {})
vim.api.nvim_create_user_command("MastodonLoadHomeTimeline", require("mastodon").fetch_home_timeline, {})
vim.api.nvim_create_user_command("MastodonLoadBookmarks", require("mastodon").fetch_bookmarks, {})
vim.api.nvim_create_user_command("MastodonLoadFavourites", require("mastodon").fetch_favourites, {})
vim.api.nvim_create_user_command("MastodonLoadReplies", require("mastodon").fetch_replies, {})
vim.api.nvim_create_user_command("MastodonReload", require("mastodon").reload_statuses, {})

local operations = require("mastodon").operations

local keymaps = vim.g.mastodon_config["keymaps"]
local default_keymaps = require("mastodon").default_config["keymaps"]

local map = vim.api.nvim_set_keymap
local default_opts = { noremap = true, silent = true }

local augroup = vim.api.nvim_create_augroup("user_cmds", { clear = false })

local get_lhs = function(keymap_scope, operation)
  local default_lhs = default_keymaps[keymap_scope][operation]
  if keymaps == nil then
    return default_lhs
  end

  if keymaps[keymap_scope] == nil then
    return default_lhs
  end

  return keymaps[keymap_scope][operation]
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "mastodon" },
  group = augroup,
  desc = "Only works on Mastodon Buffers",
  callback = function(event)
    -- if keymap starts with `,m`,
    -- buffer-wide or system-wide commands should be called
    local buffer_wide_operations = { "reload-statuses", "scroll-to-top", "scroll-to-bottom" }
    for _, operation in ipairs(buffer_wide_operations) do
      local lhs = get_lhs("buffer-wide-keymaps", operation)
      local rhs = operations["buffer-wide-keymaps"][operation]
      map("n", lhs, rhs, default_opts)
    end

    -- If keymap starts with `,t`
    -- status-wide commands should be called
    local status_wide_operations = { "reply", "bookmark", "favourite", "boost", "print" }
    for _, operation in ipairs(status_wide_operations) do
      local lhs = get_lhs("buffer-wide-keymaps", operation)
      local rhs = operations["buffer-wide-keymaps"][operation]
      map("n", lhs, rhs, default_opts)
    end
  end,
})

local system_wide_operations = { "home-timeline", "bookmarks", "favourites", "mentions", "post-message", "select-account" }
for _, operation in ipairs(system_wide_operations) do
  local lhs = get_lhs("system-wide-keymaps", operation)
  local rhs = operations["system-wide-keymaps"][operation]
  map("n", lhs, rhs, default_opts)
end
