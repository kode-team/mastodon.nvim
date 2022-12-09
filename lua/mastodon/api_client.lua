local curl = require("plenary.curl")

local db_client = require("mastodon.db_client")

local M = {}

M.fetch_home_timeline = function()
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/timelines/home"

  local res = curl.get(url, {
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    }
  })

  local statuses = vim.fn.json_decode(res.body)
  return statuses
end

M.post_message = function(message)
  local active_account = db_client:get_active_account()[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/statuses"

  local res = curl.post(url, {
    body = vim.fn.json_encode({
      status = message,
      media_ids = {},
      sensitive = false,
      spoiler_text = "",
      visibility = "unlisted",
      poll = nil,
      language = "ko",
    }),
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    }
  })

  local content = vim.fn.json_decode(res.body)["content"]
  return content
end

return M