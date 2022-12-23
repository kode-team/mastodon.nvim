local api_client = require('mastodon.api_client')
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

return M
