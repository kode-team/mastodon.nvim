-- module represents a lua module for the plugin
local db_client = require("mastodon.db_client")
local api_client= require("mastodon.api_client")

local vim = vim

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

  local active_account = db_client:get_active_account()[1]

  local access_token = active_account.access_token
  local instance_url = active_account.instance_url

  cmd = cmd .. " " .. "'" .. instance_url .. "/api/v1/statuses'"
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
    local username = json['display_name'] .. "<@" .. json['username'] .. ">"
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

M.select_account = function()
  local accounts = db_client:get_all_accounts()
  local length = #accounts

  if length == 0 then
    return nil
  end

  local active_accounts = db_client:get_active_account()
  if #active_accounts == 0 then
    active_account = nil
  else
    active_account = active_accounts[1]
  end
  selected_account = nil
  vim.ui.select(accounts, {
    prompt = 'Select your mastodon account',
    format_item = function(account)
      local formatted_name = ''

      if active_account ~= nil and account.id == active_account.id then
        formatted_name = formatted_name .. '(selected) '
      end
      return formatted_name .. account.username .. " / " .. account.instance_url
    end
  }, function(account)
    local params = { id = account.id }
    db_client:set_active_account(params)
    vim.notify("Logged in to " .. account.username .. ' / ' .. account.instance_url)
    selected_account = account

    return account
  end)

  return selected_account
end

local function split_by_chunk(text, chunk_size)
    local s = {}
    for i=1, #text, chunk_size do
        s[#s+1] = text:sub(i, i + chunk_size - 1)
    end
    return s
end

M.fetch_home_timeline = function()
  local active_accounts = db_client:get_active_account()

  vim.cmd('vsplit')
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_win_set_buf(win, buf)

  local statuses = api_client.fetch_home_timeline()

  local bufnr = vim.api.nvim_get_current_buf()

  local namespaces = vim.api.nvim_get_namespaces()
  local mastodon_ns = namespaces['MastodonNS']

  messages = {}
  local line_number = 0
  local line_numbers = {}
  for i, status in ipairs(statuses) do
    local account = status['account']
    if account ~= nil then
      local message = "@" .. account['username']
      message = message .. "(" .. (account['display_name']) .. ")"
      table.insert(messages, message)
      table.insert(line_numbers, line_number)
      line_number = line_number + 1

      local whole_message = status['content']
      local width = vim.api.nvim_win_get_width(win)

      -- (width - 10) interpolates sign column's length and line number column's length
      chunks = split_by_chunk(whole_message, width - 10)
      for i, chunk in ipairs(chunks) do
        table.insert(messages, chunk)
        line_number = line_number + 1
      end

      message = '-----------------------'
      table.insert(messages, message)
      line_number = line_number + 1
    end
  end

  vim.api.nvim_buf_set_name(bufnr, "Mastodon Home")
  vim.api.nvim_buf_set_option(bufnr, "filetype", "mastodon")
  vim.api.nvim_buf_set_lines(0, 0, 0, 'true', messages)
  vim.api.nvim_win_set_hl_ns(win, mastodon_ns)

  for _, line_number in ipairs(line_numbers) do
    vim.api.nvim_buf_add_highlight(bufnr, mastodon_ns, "MastodonHandle", line_number, 0, -1)
  end
end

return M
