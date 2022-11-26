-- module represents a lua module for the plugin
local M = {}

vim.notify = require("notify")

vim.notify.setup({
  background_colour = "#000000"
})

local utils = require('mastodon.utils')

M.greeting = function()
  return "hello world!"
end

M.toot_message = function(message)
  local cmd = "curl"

  local access_token = os.getenv("MASTODON_ACCESS_TOKEN")

  cmd = cmd .. " " .. "'https://social.silicon.moe/api/v1/statuses'"
  cmd = cmd .. " -s"
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
  local message = utils.parse_json(response)["content"]
  vim.notify(message, "info", {
    title = "(Mastodon.nvim) 툿 게시 성공!"
  })

  return response
end

M.add_account = function()
  local cmd = "curl"

  instance_url = vim.fn.input({ prompt = 'Enter your fediverse instance url (ex: https://social.silicon.moe): '})
  access_token = vim.fn.input({ prompt = 'Enter your access_token : ' })

  cmd = cmd .. " " .. "'" .. instance_url .. "/api/v1/apps/verify_credentials'"
  cmd = cmd .. " -s"
  cmd = cmd .. " -X " .. "GET"
  cmd = cmd .. " -H " .. "'Accept: application/json'"
  cmd = cmd .. " -H " .. "'Content-Type: application/json'"
  cmd = cmd .. " -H " .. "'Authorization: Bearer " .. access_token .. "'"

  local response = utils.execute_curl(cmd)
  local app_name = utils.parse_json(response)["name"]

  if app_name ~= nil then
    cmd = "curl"

    cmd = cmd .. " " .. "'" .. instance_url .. "/api/v1/accounts/verify_credentials'"
    cmd = cmd .. " -s"
    cmd = cmd .. " -X " .. "GET"
    cmd = cmd .. " -H " .. "'Accept: application/json'"
    cmd = cmd .. " -H " .. "'Content-Type: application/json'"
    cmd = cmd .. " -H " .. "'Authorization: Bearer " .. access_token .. "'"

    response = utils.execute_curl(cmd)
    json = utils.parse_json(response)
    local username = json['display_name'] .. "(@" .. json['username'] .. ")"
    local description = json['source']['note']

    db_client:add_account({
      instance_url = instance_url,
      access_token = access_token,
      username     = username,
      description  = description
    })

    return false
  else
    return true
  end
end
return M
