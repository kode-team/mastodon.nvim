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

M.toot_message = function()
  local message = vim.fn.input({prompt = "Enter your message: " })
  local content = api_client.post_message(message)

  vim.notify(content, "info", {
    title = "(Mastodon.nvim) 툿 게시 성공!"
  })

  M.reload_statuses()

  return content
end

M.add_account = function()
  instance_url = vim.fn.input({ prompt = 'Enter your fediverse instance url (ex: https://social.silicon.moe): '})
  access_token = vim.fn.input({ prompt = 'Enter your access_token : ' })

  local result = api_client.verify_credentials_for_app(instance_url, access_token)
  local app_name = result["name"]

  if app_name ~= nil then
    local json = api_client.verify_credentials_for_account(instance_url, access_token)
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
  local statuses = api_client.fetch_home_timeline()
  local bufnr = 0
  local buf = nil
  local target_buf_name = "Mastodon Home"
  local target_buffer = utils.find_buffer_by_name(target_buf_name)
  if target_buffer ~= -1 then
    buf = target_buffer
    vim.api.nvim_buf_delete(buf, {})

    buf = vim.api.nvim_create_buf(true, true)
  else
    vim.cmd('vsplit')
    buf = vim.api.nvim_create_buf(true, true)
  end

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  bufnr = vim.api.nvim_get_current_buf()
  renderer.render_home_timeline(bufnr, win, statuses)

  vim.api.nvim_win_set_cursor(0, {1, 0})
end

M.fetch_bookmarks = function()
  local statuses = api_client.fetch_bookmarks()
  local bufnr = 0
  local buf = nil
  local target_buf_name = "Mastodon Bookmark"
  local target_buffer = utils.find_buffer_by_name(target_buf_name)
  if target_buffer ~= -1 then
    buf = target_buffer
    vim.api.nvim_buf_delete(buf, {})

    buf = vim.api.nvim_create_buf(true, true)
  else
    vim.cmd('vsplit')
    buf = vim.api.nvim_create_buf(true, true)
  end

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  bufnr = vim.api.nvim_get_current_buf()
  renderer.render_bookmarks(bufnr, win, statuses)

  vim.api.nvim_win_set_cursor(0, {1, 0})
end

M.fetch_favourites = function()
  local statuses = api_client.fetch_favourites()
  local bufnr = 0
  local buf = nil
  local target_buf_name = "Mastodon Favourites"
  local target_buffer = utils.find_buffer_by_name(target_buf_name)
  if target_buffer ~= -1 then
    buf = target_buffer
    vim.api.nvim_buf_delete(buf, {})

    buf = vim.api.nvim_create_buf(true, true)
  else
    vim.cmd('vsplit')
    buf = vim.api.nvim_create_buf(true, true)
  end

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  bufnr = vim.api.nvim_get_current_buf()
  renderer.render_favourites(bufnr, win, statuses)

  vim.api.nvim_win_set_cursor(0, {1, 0})
end

M.fetch_replies = function()
  local statuses = api_client.fetch_replies()
  local bufnr = 0
  local buf = nil
  local target_buf_name = "Mastodon Replies"
  local target_buffer = utils.find_buffer_by_name(target_buf_name)
  if target_buffer ~= -1 then
    buf = target_buffer
    vim.api.nvim_buf_delete(buf, {})

    buf = vim.api.nvim_create_buf(true, true)
  else
    vim.cmd('vsplit')
    buf = vim.api.nvim_create_buf(true, true)
  end

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  bufnr = vim.api.nvim_get_current_buf()
  renderer.render_replies(bufnr, win, statuses)

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
  elseif string.find(buf_name, "Mastodon Favourites") then
    local new_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_win_set_buf(win, new_buf)
    vim.api.nvim_buf_delete(bufnr, {})
    bufnr = new_buf

    local statuses = api_client.fetch_favourites()
    renderer.render_favourites(bufnr, win, statuses)

    vim.api.nvim_win_set_cursor(0, {1, 0})
  elseif string.find(buf_name, "Mastodon Replies") then
    local new_buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_win_set_buf(win, new_buf)
    vim.api.nvim_buf_delete(bufnr, {})
    bufnr = new_buf

    local statuses = api_client.fetch_replies()
    renderer.render_favourites(bufnr, win, statuses)

    vim.api.nvim_win_set_cursor(0, {1, 0})
  end
end

return M
