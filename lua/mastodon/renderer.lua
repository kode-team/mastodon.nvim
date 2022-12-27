local utils = require("mastodon.utils")
local Parser = require("mastodon.parser")

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

local function flatten_nodes(list, node)
  table.insert(list, node)
  if node.children ~= nil then
    for _, child in ipairs(node.children) do
      flatten_nodes(list, child)
    end
  end
end

local function render_lines(nodes)
  local line = ""
  local list_depth = 0
  local lines = {}
  for _, node in ipairs(nodes) do
    local tag = node.tag
    local text = node.text

    if tag ~= nil then
      if tag:sub(1,1) ~= '/' then
        if tag == 'p' then
          if #line ~= 0 then
            table.insert(lines, line)
            line = ""
          end
        elseif tag == 'blockquote' then
          if #line ~= 0 then
            table.insert(lines, line)
            line = ""
          end
        elseif tag == 'br' or tag == 'br/' or tag == 'br /' then
          table.insert(lines, line)
          line = ""
        elseif tag == 'ul' or tag == 'ol' then
          list_depth = list_depth + 1
          if #line ~= 0 then
            table.insert(lines, line)
            line = ""
          end
        end
      else
        if tag:sub(1,3) == "/li" then
          table.insert(lines, string.rep(" ", list_depth) .. "*" .. line)
          line = ""
        elseif tag:sub(1,11) == '/blockquote' then
          table.insert(lines, line)
          line = ""
        elseif tag:sub(1,2) == "/p" then
          table.insert(lines, line)
          line = ""
        end
      end
    else
      line = line .. text
    end
  end

  if #line ~= 0 then
    table.insert(lines, line)
  end

  return lines
end

local function prepare_statuses(statuses, width)
  local lines = {}
  local metadata = {}

  local line_number = 0
  local line_numbers = {}

  local reply_action_icon = '💬'
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
      line = "@" .. account['acct']
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

    local mentions = status["mentions"]
    local displayed_mentions = ""
    for _, mention in ipairs(mentions) do
      displayed_mentions = displayed_mentions .. " @" .. mention['acct']
    end

    if #mentions == 0 then
      displayed_mentions = " self"
    end

    if status['in_reply_to_id'] ~= vim.NIL then
      table.insert(lines, "(Replying to:" .. displayed_mentions .. ")")
      table.insert(metadata, {
        line_number = line_number,
        data = json,
      })
      line_number = line_number + 1
    end


    table.insert(lines, "")
    table.insert(line_numbers, line_number)
    table.insert(metadata, {
      line_number = line_number,
      data = json,
    })
    line_number = line_number + 1

    local whole_message = target_status['content']

    local parser = Parser:new(whole_message)
    local root_node = parser:parse()
    local nodes = {}
    flatten_nodes(nodes, root_node)

    local rendered_lines = render_lines(nodes)

    for _, rendered_line in ipairs(rendered_lines) do
      table.insert(lines, rendered_line)
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

    local media_attachments = target_status["media_attachments"]
      if #media_attachments ~= 0 then
      for j, attachment in ipairs(media_attachments) do
        table.insert(lines, "Attachment " .. j .. ") " .. attachment['url'])
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
    end

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

local function render_statuses(bufnr, win, statuses, buf_name, mode)
  local namespaces = vim.api.nvim_get_namespaces()
  local mastodon_ns = namespaces['MastodonNS']

  local width = vim.api.nvim_win_get_width(win)
  local result = prepare_statuses(statuses, width)
  local lines = result.lines
  local line_numbers = result.line_numbers
  local metadata = result.metadata

  local offset = 0
  vim.api.nvim_buf_set_name(bufnr, buf_name)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "mastodon")
  if mode == "prepend" then
    offset = 0
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, 'true', lines)
  elseif mode == "append" then
    offset = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, 'true', lines)
  end

  vim.api.nvim_win_set_hl_ns(win, mastodon_ns)

  for _, line_number in ipairs(line_numbers) do
    vim.api.nvim_buf_add_highlight(bufnr, mastodon_ns, "MastodonHandle", offset + line_number, 0, -1)
  end

  for _, metadata_for_line in ipairs(metadata) do
    vim.api.nvim_buf_set_extmark(bufnr, mastodon_ns, offset + metadata_for_line.line_number, 0, {
      virt_text = {{metadata_for_line.data, "Whitespace"}},
    })
  end
end

M.render_home_timeline = function(bufnr, win, statuses, options)
  local mode = "prepend"
  if options ~= nil then
    mode = options.mode
  end
  render_statuses(bufnr, win, statuses, "Mastodon Home", mode)
end

M.render_bookmarks = function(bufnr, win, statuses, options)
  local mode = "prepend"
  if options ~= nil then
    mode = options.mode
  end
  render_statuses(bufnr, win, statuses, "Mastodon Bookmark", mode)
end

M.render_favourites = function(bufnr, win, statuses, options)
  local mode = "prepend"
  if options ~= nil then
    mode = options.mode
  end
  render_statuses(bufnr, win, statuses, "Mastodon Favourites", mode)
end

M.render_replies = function(bufnr, win, statuses, options)
  local mode = "prepend"
  if options ~= nil then
    mode = options.mode
  end
  render_statuses(bufnr, win, statuses, "Mastodon Replies", mode)
end

M.flatten_nodes = flatten_nodes
M.render_lines = render_lines

return M
