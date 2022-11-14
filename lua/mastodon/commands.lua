-- module represents a lua module for the plugin
local M = {}

local utils = require('mastodon.utils')

M.greeting = function()
  return "hello world!"
end

M.toot_message = function(message)
  local cmd = "curl"

  local access_token = os.getenv("MASTODON_ACCESS_TOKEN")

  cmd = cmd .. " " .. "'https://social.silicon.moe/api/v1/statuses'"
  cmd = cmd .. " -X " .. "POST"
  cmd = cmd .. " -H " .. "'Accept: application/json'"
  cmd = cmd .. " -H " .. "'Content-Type: application/json'"
  cmd = cmd .. " -H " .. "'Authorization: Bearer " .. access_token .. "'"

  cmd = cmd .. " --data-raw " .. "$'{"
  cmd = cmd .. "\"status\":" .. message
  cmd = cmd .. ",\"in_reply_to_id\":null"
  cmd = cmd .. ",\"media_ids\":[]"
  cmd = cmd .. ",\"sensitive\":false"
  cmd = cmd .. ",\"spoiler_text\":\"\""
  cmd = cmd .. ",\"visibility\":\"unlisted\""
  cmd = cmd .. ",\"poll\": null"
  cmd = cmd .. ",\"language\":\"ko\""
  cmd = cmd .. "}'"

  local response = utils.execute_curl(cmd)
  return response
end

return M
