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

return M
