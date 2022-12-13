local api_client = require('mastodon.api_client')

local M = {}

M.print_verbose_information = function()
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

  local status_id = vim.fn.json_decode(metadata)['status_id']
  local status = api_client.get_status(status_id)
  print(vim.fn.json_encode(status))
end

return M
