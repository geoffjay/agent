-- Framed MessagePack implementation to solve TCP message boundary issues
local simple_msgpack = require("agent.simple_msgpack")

local M = {}

-- Pack with 4-byte length prefix (same format as Go's msgpack decoder expects)
function M.encode(obj)
  local msgpack_data = simple_msgpack.pack(obj)
  local length = #msgpack_data
  -- Big-endian 4-byte length prefix + msgpack data
  return string.pack(">I4", length) .. msgpack_data
end

-- Unpack raw msgpack data (without length prefix - socket.lua handles framing)
function M.unpack(data)
  return simple_msgpack.unpack(data)
end

-- Legacy aliases
M.pack = M.encode
M.decode = M.unpack

return M 
