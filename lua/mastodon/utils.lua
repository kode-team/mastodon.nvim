local M = {}

M.trim = function(s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

M.scroll_to_top = function()
  vim.api.nvim_win_set_cursor(0, {1, 0})
end

M.scroll_to_bottom = function()
  local target = vim.api.nvim_buf_line_count(0)
  vim.api.nvim_win_set_cursor(0, {target, 0})
end

M.execute_curl = function(curl_command)
  local handle = io.popen(curl_command, 'r')
  local response = handle:read("*a")
  handle.close()

  return response
end

M.parse_json = function(response)
  result = vim.fn.json_decode(response)
  return result
end

-- See https://stackoverflow.com/questions/30995246/substring-of-a-stdstring-in-utf-8-c11/30995892#30995892
M.utf8_substr = function(text, start, finish)
  local len = finish - start + 1

  if (text == nil) then
    return ""
  end
  if (len == 0) then
    return ""
  end

  local i = 1
  local min = #text + 1
  local max = #text + 1
  local q = 1
  local ix = #text
  local ii = nil

  -- NOTE : assigning local variable i  within for statement doesnt allow `i = i +2`
  for _=1, ix, 1 do
    if (i > ix) then
      break
    end
    if (q == start) then
      min = i
    end
    if (q <= finish) then
      max = i
    end

    local char = text:sub(i,i)
    if char == nil then
      break
    end

    local code = char:byte()
    if (code >= 0 and code <= 127) then
      i = i + 0
    elseif (bit.band(code, 0xE0) == 0xC0) then
      i = i + 1
    elseif (bit.band(code, 0xF0) == 0xE0) then
      i = i + 2
    elseif (bit.band(code, 0xF8) == 0xF0) then
      i = i + 3
    elseif (bit.band(code, 0xFC) == 0xF8) then
      i = i + 4
    elseif (bit.band(code, 0xFE) == 0xFC) then
      i = i + 5
    else
      return ""
    end

    q = q + 1
    ii = i
    i = i + 1
  end

  if (q <= finish or len == 0) then
    max = ii
  end

  return text:sub(min, max)
end

M.find_buffer_by_name = function(name)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local buf_name = vim.api.nvim_buf_get_name(buf)
    if string.find(buf_name, name) then
      return buf
    end
  end
  return -1
end

-- definition of Stack data structure
local Stack = {}

function Stack.new()
  local o = setmetatable({}, Stack)
  o.__index = o.self
  o.items = {}
  return o
end


Stack.__index = Stack

function Stack:__tostring()
  return string.format("Stack (with length %d)", #self.items)
end

function Stack:push(item)
  table.insert(self.items, item)
end

function Stack:size()
  return #self.items
end

function Stack:pop()
  if #self.items == 0 then
    return nil
  end

  return table.remove(self.items)
end

function Stack:top()
  if #self.items == 0 then
    return nil
  end

  return self.items[#self.items]
end

M.Stack = Stack

return M
