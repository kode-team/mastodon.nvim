-- module represents a lua module for the plugin
local db_client = require("mastodon.db_client")
local api_client= require("mastodon.api_client")
local renderer = require("mastodon.renderer")

local vim = vim

local M = {}

vim.notify = require("notify")

vim.notify.setup({
  background_colour = "#000000"
})

local utils = require('mastodon.utils')

M.toot_message = function(message)
  local content = api_client.post_message(message)

  vim.notify(content, "info", {
    title = "(Mastodon.nvim) 툿 게시 성공!"
  })

  M.reload_statuses()

  return content
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


M.fetch_home_timeline = function()
  local active_accounts = db_client:get_active_account()

  vim.cmd('vsplit')
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_win_set_buf(win, buf)

  local statuses = api_client.fetch_home_timeline()
  local bufnr = vim.api.nvim_get_current_buf()

  renderer.render_home_timeline(bufnr, win, statuses)

  vim.api.nvim_win_set_cursor(0, {1, 0})
end

M.fetch_bookmarks = function()
  vim.cmd('vsplit')
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_win_set_buf(win, buf)

  local statuses = api_client.fetch_bookmarks()
  local bufnr = vim.api.nvim_get_current_buf()

  renderer.render_bookmarks(bufnr, win, statuses)

  vim.api.nvim_win_set_cursor(0, {1, 0})
end

M.reload_statuses = function()
  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()

  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  -- If we set buffer's name using nvim_set_buf_name, nvim_get_buf_name returns "$HOME/buf_name"
  if string.find(buf_name, "Mastodon Home") then
    local new_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_win_set_buf(win, new_buf)
    vim.api.nvim_buf_delete(bufnr, {})
    bufnr = new_buf

    local statuses = api_client.fetch_home_timeline()
    renderer.render_home_timeline(bufnr, win, statuses)

    vim.api.nvim_win_set_cursor(0, {1, 0})
  elseif string.find(buf_name, "Mastodon Bookmark") then
    local new_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_win_set_buf(win, new_buf)
    vim.api.nvim_buf_delete(bufnr, {})
    bufnr = new_buf

    local statuses = api_client.fetch_bookmarks()
    renderer.render_bookmarks(bufnr, win, statuses)

    vim.api.nvim_win_set_cursor(0, {1, 0})
  end
end

return M
