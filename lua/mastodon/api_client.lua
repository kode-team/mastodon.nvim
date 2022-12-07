local db_client = require("mastodon.db_client")
local utils = require("mastodon.utils")

local M = {}

M.fetch_home_timeline = function()
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local cmd = 'curl'

  cmd = cmd .. " " .. "'" .. instance_url .. "/api/v1/timelines/home"

  cmd = cmd .. "'"
  cmd = cmd .. " -s"
  cmd = cmd .. " -X " .. "GET"
  cmd = cmd .. " -H " .. "'Accept: application/json'"
  cmd = cmd .. " -H " .. "'Content-Type: application/json'"
  cmd = cmd .. " -H " .. "'Authorization: Bearer " .. access_token .. "'"

  local response = utils.execute_curl(cmd)
  local statuses = utils.parse_json(response)

  return statuses
end

return M
