-- module represents a lua module for the plugin
local db_client = require("mastodon.db_client")
local api_client = require("mastodon.api_client")
local renderer = require("mastodon.renderer")

local vim = vim

local M = {}

vim.notify = require("notify")

vim.notify.setup({
  background_colour = "#000000",
})

local utils = require("mastodon.utils")

M.toot_message = function()
  local active_accounts = db_client:get_active_account()
  local active_account = active_accounts[1]
  local prompt_message = "-- Your current account is " .. active_account.username .. " --" .. "\nEnter your message: "
  local message = vim.fn.input({ prompt = prompt_message })
  local unescaped_message = string.gsub(message, "\\n", "\n")
  local content = api_client.post_message(unescaped_message)

  vim.notify(content, "info", {
    title = "(Mastodon.nvim) Posted message",
  })

  M.reload_statuses()

  return content
end

M.add_account = function()
  instance_url = vim.fn.input({ prompt = "Enter your fediverse instance url (ex: https://social.silicon.moe): " })
  access_token = utils.trim(vim.fn.input({ prompt = "Enter your access_token : " }))

  local result = api_client.verify_credentials_for_app(instance_url, access_token)
  local app_name = result["name"]

  if app_name ~= nil then
    local json = api_client.verify_credentials_for_account(instance_url, access_token)
    local username = json["display_name"] .. "<@" .. json["username"] .. ">"
    local description = json["source"]["note"]

    db_client:add_account({
      instance_url = instance_url,
      access_token = access_token,
      username = username,
      description = description,
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
    prompt = "Select your mastodon account",
    format_item = function(account)
      local formatted_name = ""

      if active_account ~= nil and account.id == active_account.id then
        formatted_name = formatted_name .. "(selected) "
      end
      return formatted_name .. account.username .. " / " .. account.instance_url
    end,
  }, function(account)
    if account ~= nil then
      local params = { id = account.id }
      db_client:set_active_account(params)
      vim.notify("Logged in to " .. account.username .. " / " .. account.instance_url)
      selected_account = account
    end
  end)

  return selected_account
end

M.fetch_home_timeline = function()
  local result = api_client.fetch_home_timeline({})
  local statuses = result.data
  local headers = result.headers

  local bufnr = 0
  local buf = nil
  local target_buf_name = "Mastodon Home"
  local target_buffer = utils.find_buffer_by_name(target_buf_name)
  if target_buffer ~= -1 then
    buf = target_buffer
    vim.api.nvim_buf_delete(buf, {})

    buf = vim.api.nvim_create_buf(true, true)
  else
    vim.cmd("vsplit")
    buf = vim.api.nvim_create_buf(true, true)
  end

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  bufnr = vim.api.nvim_get_current_buf()
  renderer.render_home_timeline(bufnr, win, statuses)

  local max_status_id = nil
  local min_status_id = nil
  max_status_id = statuses[1]["id"]
  min_status_id = statuses[#statuses]["id"]

  if max_status_id ~= nil then
    if vim.b[bufnr].max_status_id == nil then
      vim.b[bufnr].max_status_id = max_status_id
    end
  end

  if min_status_id ~= nil then
    if vim.b[bufnr].min_status_id == nil then
      vim.b[bufnr].min_status_id = min_status_id
    end
  end
end

M.fetch_bookmarks = function()
  local result = api_client.fetch_bookmarks()
  local statuses = result.data
  local headers = result.headers

  local bufnr = 0
  local buf = nil
  local target_buf_name = "Mastodon Bookmark"
  local target_buffer = utils.find_buffer_by_name(target_buf_name)
  if target_buffer ~= -1 then
    buf = target_buffer
    vim.api.nvim_buf_delete(buf, {})

    buf = vim.api.nvim_create_buf(true, true)
  else
    vim.cmd("vsplit")
    buf = vim.api.nvim_create_buf(true, true)
  end

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  bufnr = vim.api.nvim_get_current_buf()

  vim.b[bufnr].prev = headers.prev
  vim.b[bufnr].next = headers.next

  renderer.render_bookmarks(bufnr, win, statuses)
end

M.fetch_favourites = function()
  local result = api_client.fetch_favourites()
  local statuses = result.data
  local headers = result.headers

  local bufnr = 0
  local buf = nil
  local target_buf_name = "Mastodon Favourites"
  local target_buffer = utils.find_buffer_by_name(target_buf_name)
  if target_buffer ~= -1 then
    buf = target_buffer
    vim.api.nvim_buf_delete(buf, {})

    buf = vim.api.nvim_create_buf(true, true)
  else
    vim.cmd("vsplit")
    buf = vim.api.nvim_create_buf(true, true)
  end

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  bufnr = vim.api.nvim_get_current_buf()

  vim.b[bufnr].prev = headers.prev
  vim.b[bufnr].next = headers.next

  renderer.render_favourites(bufnr, win, statuses)
end

M.fetch_replies = function()
  local result = api_client.fetch_replies()
  local statuses = result.data
  local headers = result.headers

  local bufnr = 0
  local buf = nil
  local target_buf_name = "Mastodon Replies"
  local target_buffer = utils.find_buffer_by_name(target_buf_name)
  if target_buffer ~= -1 then
    buf = target_buffer
    vim.api.nvim_buf_delete(buf, {})

    buf = vim.api.nvim_create_buf(true, true)
  else
    vim.cmd("vsplit")
    buf = vim.api.nvim_create_buf(true, true)
  end

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  bufnr = vim.api.nvim_get_current_buf()

  vim.b[bufnr].prev = headers.prev
  vim.b[bufnr].next = headers.next

  renderer.render_replies(bufnr, win, statuses)
end

M.reload_statuses = function()
  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()

  local buf_name = vim.api.nvim_buf_get_name(bufnr)

  local fetch_statuses = nil
  local render_statuses = nil

  -- If we set buffer's name using nvim_set_buf_name, nvim_get_buf_name returns "$HOME/buf_name"
  if string.find(buf_name, "Mastodon Home") then
    fetch_statuses = api_client.fetch_home_timeline
    render_statuses = renderer.render_home_timeline
  elseif string.find(buf_name, "Mastodon Bookmark") then
    fetch_statuses = api_client.fetch_bookmarks
    render_statuses = renderer.render_bookmarks
  elseif string.find(buf_name, "Mastodon Favourites") then
    fetch_statuses = api_client.fetch_favourites
    render_statuses = renderer.render_favourites
  elseif string.find(buf_name, "Mastodon Replies") then
    fetch_statuses = api_client.fetch_replies
    render_statuses = renderer.render_replies
  end

  local result = fetch_statuses({})
  local statuses = result.data
  local headers = result.headers

  local new_buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_win_set_buf(win, new_buf)
  vim.api.nvim_buf_delete(bufnr, {})
  bufnr = new_buf

  vim.b[bufnr].prev = headers.prev
  vim.b[bufnr].next = headers.next

  local max_status_id = nil
  local min_status_id = nil
  max_status_id = statuses[1]["id"]
  min_status_id = statuses[#statuses]["id"]

  if max_status_id ~= nil then
    if vim.b[bufnr].max_status_id == nil then
      vim.b[bufnr].max_status_id = max_status_id
    end
  end

  if min_status_id ~= nil then
    if vim.b[bufnr].min_status_id == nil then
      vim.b[bufnr].min_status_id = min_status_id
    end
  end

  render_statuses(bufnr, win, statuses, { mode = 'prepend' })
end

M.fetch_older_statuses = function()
  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()

  local min_status_id = vim.b[bufnr].min_status_id
  local next = vim.b[bufnr].next

  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  local fetch_statuses = api_client.fetch_home_timeline
  local render_statuses = renderer.render_home_timeline

  if string.find(buf_name, "Mastodon Home") then
    fetch_statuses = api_client.fetch_home_timeline
    render_statuses = renderer.render_home_timeline
  elseif string.find(buf_name, "Mastodon Bookmark") then
    fetch_statuses = api_client.fetch_bookmarks
    render_statuses = renderer.render_bookmarks
  elseif string.find(buf_name, "Mastodon Favourites") then
    fetch_statuses = api_client.fetch_favourites
    render_statuses = renderer.render_favourites
  elseif string.find(buf_name, "Mastodon Replies") then
    fetch_statuses = api_client.fetch_replies
    render_statuses = renderer.render_replies
  end

  if string.find(buf_name, "Mastodon") then
    if string.find(buf_name, "Mastodon Home") then
      local statuses = fetch_statuses({ max_id = min_status_id }).data
      if #statuses > 0 then
        min_status_id = statuses[#statuses]["id"]

        if min_status_id ~= nil then
          vim.b[bufnr].min_status_id = min_status_id
        end
      end

      render_statuses(bufnr, win, statuses, { mode = "append" })
    else
      if next == nil then
        vim.notify("There is no more contents to fetch", "info", {
          title = "Mastodon.nvim"
        })
        return
      end

      local max_id = nil
      local _, _, _, matched = string.find(next, "(max_id=)(%d+)")
      max_id = matched

      local result = fetch_statuses({ max_id = max_id })
      local statuses = result.data
      local headers = result.headers

      vim.b[bufnr].next = headers.next

      render_statuses(bufnr, win, statuses, { mode = "append" })
    end
  end
end

M.fetch_newer_statuses = function()
  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()
  local max_status_id = vim.b[bufnr].max_status_id
  local prev = vim.b[bufnr].prev

  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  local fetch_statuses = api_client.fetch_home_timeline
  local render_statuses = renderer.render_home_timeline

  if string.find(buf_name, "Mastodon Home") then
    fetch_statuses = api_client.fetch_home_timeline
    render_statuses = renderer.render_home_timeline
  elseif string.find(buf_name, "Mastodon Bookmark") then
    fetch_statuses = api_client.fetch_bookmarks
    render_statuses = renderer.render_bookmarks
  elseif string.find(buf_name, "Mastodon Favourites") then
    fetch_statuses = api_client.fetch_favourites
    render_statuses = renderer.render_favourites
  elseif string.find(buf_name, "Mastodon Replies") then
    fetch_statuses = api_client.fetch_replies
    render_statuses = renderer.render_replies
  end

  if string.find(buf_name, "Mastodon") then
    if string.find(buf_name, "Mastodon Home") then
      local statuses = fetch_statuses({ min_id = max_status_id }).data
      if #statuses > 0 then
        max_status_id = statuses[1]["id"]

        if max_status_id ~= nil then
          vim.b[bufnr].max_status_id = max_status_id
        end
      end

      render_statuses(bufnr, win, statuses, { mode = "prepend" })
    else
      if prev == nil then
        return
      end

      local min_id = nil
      local _, _, _, matched = string.find(prev, "(min_id=)(%d+)")
      min_id = matched

      local result = fetch_statuses({ min_id = min_id })
      local statuses = result.data
      local headers = result.headers

      vim.b[bufnr].prev = headers.prev

      render_statuses(bufnr, win, statuses, { mode = "prepend" })
    end
  end
end

return M
