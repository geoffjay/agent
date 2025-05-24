local M = {}

-- Try multiple msgpack implementations in order of preference
local msgpack = nil
local msgpack_type = "none"

-- Try vim's built-in msgpack first
local success, lib = pcall(require, "msgpack")
if success and lib.pack and lib.unpack then
  msgpack = lib
  msgpack_type = "vim-builtin"
else
  -- Try lua-msgpack-native
  success, lib = pcall(require, "MessagePack")
  if success and lib.pack and lib.unpack then
    msgpack = lib
    msgpack_type = "lua-msgpack-native"
  else
    -- Try mpack
    success, lib = pcall(require, "mpack")
    if success and lib.encode and lib.decode then
      msgpack = {
        pack = lib.encode,
        unpack = lib.decode
      }
      msgpack_type = "mpack"
    end
  end
end

if msgpack then
  -- Use native msgpack
  M.encode = msgpack.pack
  M.decode = msgpack.unpack
  M.is_native = function() return true end
  M.get_type = function() return msgpack_type end
else
  -- Fallback to simple built-in implementation
  local simple_msgpack = require("agent.simple_msgpack")
  M.encode = simple_msgpack.pack
  M.decode = simple_msgpack.unpack
  M.is_native = function() return true end
  M.get_type = function() return "simple-builtin" end
end

return M 
