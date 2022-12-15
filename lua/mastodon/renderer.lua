local utils = require("mastodon.utils")

local M = {}

local function split_by_chunk(text, chunk_size)
    local s = {}
    for i=1, #text, chunk_size do
        s[#s+1] = utils.utf8_substr(text, i, i + chunk_size - 1)
    end
    return s
end

local function is_reblog(status)
  return status['reblog'] ~= vim.NIL
end

local function prepare_statuses(statuses, width)
  local lines = {}
  local metadata = {}

  local line_number = 0
  local line_numbers = {}

  local reply_action_icon = '↩️'
  local favourite_action_icon = '💗'
  local boost_action_icon = '🚀'
  local bookmark_action_icon = '🔖'
  local check_icon = '✔️'

  for i, status in ipairs(statuses) do
    local target_status = nil
    local line = nil
    local account = status['account']
    if is_reblog(status) then
      target_status = status['reblog']
      line = "@" .. target_status['account']['username']
      line = line .. "(" .. target_status['account']['display_name']  .. ")"
      line = line .. " --- boosted by @" .. account['username']
      line = line .. "(" .. (account['display_name']) .. ")"
    else
      target_status = status
      line = "@" .. account['username']
      line = line .. "(" .. (account['display_name']) .. ")"
    end
    local status_id = status['id']
    local url = status['uri']
    local json = vim.fn.json_encode({
      status_id = status_id,
      url = url,
    })

    table.insert(lines, line)
    table.insert(line_numbers, line_number)
    table.insert(metadata, {
      line_number = line_number,
      data = json,
    })
    line_number = line_number + 1

    local whole_message = target_status['content']

    -- (width - 10) interpolates sign column's length and line number column's length
    local chunks = split_by_chunk(whole_message, width - 10)
    for i, chunk in ipairs(chunks) do
      table.insert(lines, chunk)
      table.insert(metadata, {
        line_number = line_number,
        data = json,
      })
      line_number = line_number + 1
    end

    table.insert(lines, "")
    table.insert(metadata, {
      line_number = line_number,
      data = json,
    })
    line_number = line_number + 1

    local bookmarked = target_status['bookmarked']
    local favourited = target_status['favourited']
    local reblogged  = target_status['reblogged']

    local reblogs_count = target_status['reblogs_count']
    local favourites_count = target_status['favourites_count']
    local replies_count = target_status['replies_count']

    line = " " .. reply_action_icon
    line = line .. "  " .. replies_count

    line = line .. "   " .. boost_action_icon
    line = line .. "  " .. reblogs_count
    if reblogged then
      line = line .. " (" .. check_icon .. ")"
    end

    line = line .. "   " .. favourite_action_icon
    line = line .. "  " .. favourites_count
    if favourited then
      line = line .. " (" .. check_icon .. ")"
    end

    line = line .. "   " .. bookmark_action_icon
    if bookmarked then
      line = line .. " (" .. check_icon .. ")"
    end

    table.insert(lines, line)
    table.insert(metadata, {
      line_number = line_number,
      data = json,
    })
    line_number = line_number + 1

    line = '-----------------------'
    table.insert(lines, line)
    table.insert(metadata, {
      line_number = line_number,
      data = json,
    })
    line_number = line_number + 1
  end

  return {
    line_numbers = line_numbers,
    lines = lines,
    metadata = metadata,
  }
end

M.render_home_timeline = function(bufnr, win, statuses)
  local namespaces = vim.api.nvim_get_namespaces()
  local mastodon_ns = namespaces['MastodonNS']

  local width = vim.api.nvim_win_get_width(win)
  local result = prepare_statuses(statuses, width)
  local lines = result.lines
  local line_numbers = result.line_numbers
  local metadata = result.metadata

  vim.api.nvim_buf_set_name(bufnr, "Mastodon Home")
  vim.api.nvim_buf_set_option(bufnr, "filetype", "mastodon")
  vim.api.nvim_buf_set_lines(0, 0, 0, 'true', lines)
  vim.api.nvim_win_set_hl_ns(win, mastodon_ns)

  for _, line_number in ipairs(line_numbers) do
    vim.api.nvim_buf_add_highlight(bufnr, mastodon_ns, "MastodonHandle", line_number, 0, -1)
  end

  for _, metadata_for_line in ipairs(metadata) do
    vim.api.nvim_buf_set_extmark(bufnr, mastodon_ns, metadata_for_line.line_number, 0, {
      virt_text = {{metadata_for_line.data, "Whitespace"}},
    })
  end
end

M.render_bookmarks = function(bufnr, win, statuses)
  local namespaces = vim.api.nvim_get_namespaces()
  local mastodon_ns = namespaces['MastodonNS']

  local width = vim.api.nvim_win_get_width(win)
  local result = prepare_statuses(statuses, width)
  local lines = result.lines
  local line_numbers = result.line_numbers
  local metadata = result.metadata

  vim.api.nvim_buf_set_name(bufnr, "Mastodon Bookmark")
  vim.api.nvim_buf_set_option(bufnr, "filetype", "mastodon")
  vim.api.nvim_buf_set_lines(0, 0, 0, 'true', lines)
  vim.api.nvim_win_set_hl_ns(win, mastodon_ns)

  for _, line_number in ipairs(line_numbers) do
    vim.api.nvim_buf_add_highlight(bufnr, mastodon_ns, "MastodonHandle", line_number, 0, -1)
  end

  for _, metadata_for_line in ipairs(metadata) do
    vim.api.nvim_buf_set_extmark(bufnr, mastodon_ns, metadata_for_line.line_number, 0, {
      virt_text = {{metadata_for_line.data, "Whitespace"}},
    })
  end
end

return M
