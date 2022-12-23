local curl = require("plenary.curl")

local db_client = require("mastodon.db_client")

local M = {}

M.get_status = function(status_id)
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/statuses/" .. status_id

  local res = curl.get(url, {
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    }
  })

  local status = vim.fn.json_decode(res.body)
  return status
end

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

M.fetch_bookmarks = function()
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/bookmarks"

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

M.fetch_favourites = function()
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/favourites"

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

M.add_bookmark = function(status_id)
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/statuses/" .. status_id .. "/bookmark"

  local res = curl.post(url, {
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    }
  })

  vim.notify("Added to bookmarks", "info", {
    title = "Mastodon.nvim"
  })

  local status = vim.fn.json_decode(res.body)
  return status
end

M.cancel_bookmark = function(status_id)
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/statuses/" .. status_id .. "/unbookmark"

  local res = curl.post(url, {
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    }
  })

  vim.notify("Removed from bookmarks", "info", {
    title = "Mastodon.nvim"
  })

  local status = vim.fn.json_decode(res.body)
  return status
end

M.add_favourite = function(status_id)
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/statuses/" .. status_id .. "/favourite"

  local res = curl.post(url, {
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    }
  })

  vim.notify("Added to favourites", "info", {
    title = "Mastodon.nvim"
  })

  local status = vim.fn.json_decode(res.body)
  return status
end

M.cancel_favourite = function(status_id)
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/statuses/" .. status_id .. "/unfavourite"

  local res = curl.post(url, {
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    }
  })

  vim.notify("Removed from favourites", "info", {
    title = "Mastodon.nvim"
  })

  local status = vim.fn.json_decode(res.body)
  return status
end

M.boost = function(status_id)
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/statuses/" .. status_id .. "/reblog"

  local res = curl.post(url, {
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    }
  })

  vim.notify("Boosted", "info", {
    title = "Mastodon.nvim"
  })

  local status = vim.fn.json_decode(res.body)
  return status
end

M.cancel_boost = function(status_id)
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/statuses/" .. status_id .. "/unreblog"

  local res = curl.post(url, {
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    }
  })

  vim.notify("Boost canceled", "info", {
    title = "Mastodon.nvim"
  })

  local status = vim.fn.json_decode(res.body)
  return status
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
