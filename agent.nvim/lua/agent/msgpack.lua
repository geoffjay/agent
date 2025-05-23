local M = {}

-- Try to use vim's built-in msgpack support first
local has_msgpack, msgpack = pcall(require, "msgpack")

if has_msgpack then
  -- Use native msgpack if available
  M.encode = msgpack.pack
  M.decode = msgpack.unpack
else
  -- Fallback to JSON with length prefix for framing
  M.encode = function(data)
    local json_str = vim.fn.json_encode(data)
    local length = string.len(json_str)
    -- 4-byte length prefix + JSON data
    return string.pack(">I4", length) .. json_str
  end
  
  M.decode = function(data)
    if string.len(data) < 4 then
      error("Insufficient data for length prefix")
    end
    
    local length = string.unpack(">I4", data, 1)
    if string.len(data) < 4 + length then
      error("Insufficient data for message body")
    end
    
    local json_str = string.sub(data, 5, 4 + length)
    return vim.fn.json_decode(json_str)
  end
end

-- Helper function to check if msgpack is available
function M.is_native()
  return has_msgpack
end

return M 
