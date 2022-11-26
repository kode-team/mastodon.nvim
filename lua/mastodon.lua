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
end

-- "greeting" is a public method for the plugin
M.greeting = function()
  print(commands.greeting())
  print(commands.greeting())
  print(commands.greeting())
  print(commands.greeting())
  print(commands.greeting())
  print(commands.greeting())
end

M.toot_message = function(opts)
  local message = opts.args
  commands.toot_message(message)
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

return M
