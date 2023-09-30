-- commands module file
local commands = require("mastodon.commands")

local M = {}
M.config = {
  -- default config
  opt = "Hello!",
}

-- setup is the public method to setup your plugin
M.setup = function(args)
  -- you can define your setup function here. Usually configurations can be merged, accepting outside params and
  -- you can also put some validation here for those.
  M.config = vim.tbl_deep_extend("force", M.config, args or {})

  namespace = vim.api.nvim_create_namespace("MastodonNS")
  local hl_for_whitespace = vim.api.nvim_get_hl(0, { name = "NormalFloat" })

  vim.api.nvim_set_hl(namespace, "MastodonHandle", {
    fg = "#000000",
    bg = "#ffffff",
    underline = true,
  })
  vim.api.nvim_set_hl(namespace, "MastodonMetadata", {
    fg = hl_for_whitespace.bg,
    bg = hl_for_whitespace.bg,
    blend = 10,
  })
end

M.toot_message = function()
  commands.toot_message()
end

M.add_account = function()
  local result = commands.add_account()
  if result ~= true then
    vim.notify("Successfully added your account!")
  else
    vim.notify("Failed to adding your account", vim.log.levels.ERROR)
  end
end

M.select_account = function()
  local account = commands.select_account()
  if account ~= nil then
  else
    vim.notify("You need to add account using :MastodonAddAccount", vim.log.levels.ERROR)
  end
end

M.fetch_home_timeline = function()
  commands.fetch_home_timeline()
end

M.fetch_bookmarks = function()
  commands.fetch_bookmarks()
end

M.fetch_favourites = function()
  commands.fetch_favourites()
end

M.fetch_replies = function()
  commands.fetch_replies()
end

M.reload_statuses = function()
  commands.reload_statuses()
end

return M
