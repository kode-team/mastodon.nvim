local M = {}

M.execute_curl = function(curl_command)
  local handle = io.popen(curl_command, 'r')
  local response = handle:read("*a")
  handle.close()

  return response
end

return M
