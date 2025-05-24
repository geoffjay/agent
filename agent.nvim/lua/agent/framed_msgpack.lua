-- Framed MessagePack implementation to solve TCP message boundary issues
local simple_msgpack = require("agent.simple_msgpack")

local M = {}

-- Provide raw MessagePack encoding (socket.lua handles framing)
function M.encode(obj)
  return simple_msgpack.pack(obj)
end

-- Provide raw MessagePack decoding (socket.lua handles framing)
function M.unpack(data)
  return simple_msgpack.unpack(data)
end

-- Legacy aliases
M.pack = M.encode
M.decode = M.unpack

-- Compatibility functions for socket.lua
M.is_native = function() return true end
M.get_type = function() return "framed-simple" end

return M 
