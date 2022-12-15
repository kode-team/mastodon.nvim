local M = {}

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

    if text:sub(i,i) == nil then
      break
    end

    local c = text:sub(i,i):byte()
    if (c >= 0 and c <= 127) then
      i = i + 0
    elseif (bit.band(c, 0xE0) == 0xC0) then
      i = i + 1
    elseif (bit.band(c, 0xF0) == 0xE0) then
      i = i + 2
    elseif (bit.band(c, 0xF8) == 0xF0) then
      i = i + 3
    elseif (bit.band(c, 0xFC) == 0xF8) then
      i = i + 4
    elseif (bit.band(c, 0xFE) == 0xFC) then
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

return M
