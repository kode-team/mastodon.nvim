local api_client = require('mastodon.api_client')
local db_client = require('mastodon.db_client')
local commands = require('mastodon.commands')

local M = {}

local function get_status_id()
  local position = vim.api.nvim_win_get_cursor(0)
  local namespaces = vim.api.nvim_get_namespaces()
  local mastodon_ns = namespaces['MastodonNS']
  local row = position[1]

  local extmark_ids = vim.api.nvim_buf_get_extmarks(0, mastodon_ns, {row, 0}, {row, -1}, {})
  local extmark_pairs = extmark_ids[1]
  local extmark_id = extmark_pairs[1]

  local extmark = vim.api.nvim_buf_get_extmark_by_id(0, mastodon_ns, extmark_id, { details = true })
  local details = extmark[3]
  local virt_text = details['virt_text'][1]
  local metadata = virt_text[1]

  return vim.fn.json_decode(metadata)['status_id']
end

M.print_verbose_information = function()
  local status_id = get_status_id()
  local status = api_client.get_status(status_id)
  print(vim.fn.json_encode(status))
end

M.toggle_bookmark = function()
  local status_id = get_status_id()
  local status = api_client.get_status(status_id)

  if status['bookmarked'] then
    api_client.cancel_bookmark(status_id)
    commands.reload_statuses()
  else
    api_client.add_bookmark(status_id)
    commands.reload_statuses()
  end
end

M.toggle_favourite = function()
  local status_id = get_status_id()

  local status = api_client.get_status(status_id)

  if status['favourited'] then
    api_client.cancel_favourite(status_id)
    commands.reload_statuses()
  else
    api_client.add_favourite(status_id)
    commands.reload_statuses()
  end
end

M.reply = function()
  local active_account = db_client:get_active_account()[1]
  local status_id = get_status_id()

  local status = api_client.get_status(status_id)

  local mention_targets = {}

  table.insert(mention_targets, status['account']['acct'])
  local mentions = status['mentions']
  for _, mention in ipairs(mentions) do
    table.insert(mention_targets, mention['acct'])
  end

  local actual_mention_targets = {}
  for _, mention in ipairs(mention_targets) do
    if not string.find(active_account.username, mention) then
      table.insert(actual_mention_targets, mention)
    end
  end

  local message = ""
  for _, acct in ipairs(actual_mention_targets) do
    message = message .. " @" .. acct
  end

  local displayed_mentions = ""
  if #actual_mention_targets == 0 then
    displayed_mentions = " self"
  else
    displayed_mentions = message
  end

  local prompt_message = "(mentioning to:" .. displayed_mentions .. ")\n" .. "Enter your message: "

  local message_body = vim.fn.input({ prompt = prompt_message })
  local unescpaed_message_body = string.gsub(message_body, "\\n", "\n")
  message = message .. " " .. unescpaed_message_body

  local content = api_client.reply(status_id, message)

  vim.notify(content, "info", {
    title = "(Mastodon.nvim) Replied to" .. displayed_mentions
  })

  commands.reload_statuses()
end

M.toggle_boost = function()
  local status_id = get_status_id()

  local status = api_client.get_status(status_id)

  if status['reblogged'] then
    api_client.cancel_boost(status_id)
    commands.reload_statuses()
  else
    api_client.boost(status_id)
    commands.reload_statuses()
  end
end

return M
