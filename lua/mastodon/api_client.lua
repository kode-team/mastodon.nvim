local curl = require("plenary.curl")

local db_client = require("mastodon.db_client")

local M = {}

local function generate_pagination_header(headers)
  local header_line = ""

  for _, line in ipairs(headers) do
    if string.find(line, "link: ") then
      header_line = line
    end
  end

  local line = header_line:sub(6, #header_line)
  local idx = string.find(line, ",")

  if idx then
    local tokens = {}
    table.insert(tokens, line:sub(1, idx - 1))
    table.insert(tokens, line:sub(idx + 1, #line))

    local prev = nil
    local next = nil

    for _, token in ipairs(tokens) do
      if string.find(token, "\"prev\"") then
        prev = token
      end

      if string.find(token, "\"next\"") then
        next = token
      end
    end

    return {
      prev = prev,
      next = next,
    }
  else
    if string.find(line, "\"prev\"") then
      return {
        next = nil,
        prev = line,
      }
    elseif string.find(line, "\"next\"") then
      return {
        next = line,
        prev = nil,
      }
    end

    return {}
  end
end

M.verify_credentials_for_app = function(instance_url, access_token)
  local url = instance_url .. "/api/v1/apps/verify_credentials"
  local res = curl.get(url, {
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    },
  })
  local result = vim.fn.json_decode(res.body)
  return result
end

M.verify_credentials_for_account = function(instance_url, access_token)
  local url = instance_url .. "/api/v1/accounts/verify_credentials"
  local res = curl.get(url, {
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    },
  })
  local result = vim.fn.json_decode(res.body)
  return result
end

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
    },
  })

  local status = vim.fn.json_decode(res.body)
  return status
end

M.fetch_home_timeline = function(params)
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]
  local query = {}

  if params.since_id ~= nil then
    query.since_id = params.since_id
  end

  if params.max_id ~= nil then
    query.max_id = params.max_id
  end

  if params.min_id ~= nil then
    query.min_id = params.min_id
  end

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/timelines/home"

  local res = curl.get(url, {
    query = query,
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    },
  })

  local statuses = vim.fn.json_decode(res.body)
  return {
    headers = {},
    data = statuses,
  }
end

M.fetch_bookmarks = function(params)
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/bookmarks"

  local res = curl.get(url, {
    query = params,
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    },
  })

  local statuses = vim.fn.json_decode(res.body)
  return {
    headers = generate_pagination_header(res.headers),
    data = statuses,
  }
end

M.fetch_favourites = function(params)
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/favourites"

  local res = curl.get(url, {
    query = params,
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    },
  })

  local statuses = vim.fn.json_decode(res.body)
  return {
    headers = generate_pagination_header(res.headers),
    data = statuses,
  }
end

M.fetch_replies = function(params)
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  local url = instance_url .. "/api/v1/notifications"

  local query = {
    types = "mention"
  }

  if params then
    if params.max_id ~= nil then
      query.max_id = params.max_id
    end

    if params.min_id ~= nil then
      query.min_id = params.min_id
    end
  end

  local res = curl.get(url, {
    query = query,
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    },
  })

  local notifications = vim.fn.json_decode(res.body)
  local statuses = {}

  for _, notification in ipairs(notifications) do
    if notification["type"] == "mention" then
      table.insert(statuses, notification["status"])
    end
  end

  return {
    headers = generate_pagination_header(res.headers),
    data = statuses,
  }
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
    },
  })

  vim.notify("Added to bookmarks", "info", {
    title = "Mastodon.nvim",
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
    },
  })

  vim.notify("Removed from bookmarks", "info", {
    title = "Mastodon.nvim",
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
    },
  })

  vim.notify("Added to favourites", "info", {
    title = "Mastodon.nvim",
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
    },
  })

  vim.notify("Removed from favourites", "info", {
    title = "Mastodon.nvim",
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
    },
  })

  vim.notify("Boosted", "info", {
    title = "Mastodon.nvim",
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
    },
  })

  vim.notify("Boost canceled", "info", {
    title = "Mastodon.nvim",
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
      visibility = vim.g.mastodon_toot_visibility or "unlisted",
      poll = nil,
      language = "ko",
    }),
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    },
  })

  local content = vim.fn.json_decode(res.body)["content"]
  return content
end

M.reply = function(status_id, message)
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
      in_reply_to_id = status_id,
    }),
    headers = {
      accept = "application/json",
      content_type = "application/json",
      authorization = "Bearer " .. access_token,
    },
  })

  local content = vim.fn.json_decode(res.body)["content"]
  return content
end

return M
