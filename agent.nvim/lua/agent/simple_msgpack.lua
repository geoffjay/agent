-- Simple MessagePack implementation for agent communication
-- Only implements the subset we need for basic message passing

local M = {}

-- MessagePack format codes
local MP_FIXMAP = 0x80
local MP_MAP16 = 0xde
local MP_FIXSTR = 0xa0
local MP_STR8 = 0xd9
local MP_STR16 = 0xda
local MP_POSITIVE_FIXINT = 0x00
local MP_UINT8 = 0xcc
local MP_UINT16 = 0xcd
local MP_UINT32 = 0xce

-- Encode a value to MessagePack format
function M.pack(obj)
  if type(obj) == "table" then
    return pack_map(obj)
  elseif type(obj) == "string" then
    return pack_str(obj)
  elseif type(obj) == "number" then
    return pack_int(obj)
  else
    error("Unsupported type: " .. type(obj))
  end
end

function pack_map(map)
  local keys = {}
  for k, _ in pairs(map) do
    table.insert(keys, k)
  end
  
  -- Sort keys for deterministic output
  table.sort(keys)
  
  local count = #keys
  local result = ""
  
  if count <= 15 then
    -- FixMap
    result = string.char(MP_FIXMAP + count)
  else
    error("Map too large for simple implementation")
  end
  
  for _, key in ipairs(keys) do
    result = result .. M.pack(key) .. M.pack(map[key])
  end
  
  return result
end

function pack_str(str)
  local len = #str
  if len <= 31 then
    -- FixStr
    return string.char(MP_FIXSTR + len) .. str
  elseif len <= 255 then
    -- str8
    return string.char(MP_STR8, len) .. str
  elseif len <= 65535 then
    -- str16
    return string.char(MP_STR16) .. string.pack(">I2", len) .. str
  else
    error("String too long for simple implementation")
  end
end

function pack_int(num)
  if num >= 0 and num <= 127 then
    -- Positive FixInt
    return string.char(num)
  elseif num <= 255 then
    -- uint8
    return string.char(MP_UINT8, num)
  elseif num <= 65535 then
    -- uint16
    return string.char(MP_UINT16) .. string.pack(">I2", num)
  elseif num <= 4294967295 then
    -- uint32
    return string.char(MP_UINT32) .. string.pack(">I4", num)
  else
    error("Number too large for simple implementation")
  end
end

-- Simplified unpack - just enough to handle responses
function M.unpack(data)
  local pos = 1
  local value, new_pos = unpack_value(data, pos)
  return value
end

function unpack_value(data, pos)
  if pos > #data then
    error("Unexpected end of data")
  end
  
  local byte = string.byte(data, pos)
  
  if byte >= MP_FIXMAP and byte < MP_FIXMAP + 16 then
    -- FixMap
    return unpack_map(data, pos, byte - MP_FIXMAP)
  elseif byte >= MP_FIXSTR and byte < MP_FIXSTR + 32 then
    -- FixStr
    return unpack_str(data, pos, byte - MP_FIXSTR)
  elseif byte <= 127 then
    -- Positive FixInt
    return byte, pos + 1
  elseif byte == MP_UINT8 then
    -- uint8
    return unpack_uint8(data, pos)
  elseif byte == MP_UINT16 then
    -- uint16
    return unpack_uint16(data, pos)
  elseif byte == MP_UINT32 then
    -- uint32
    return unpack_uint32(data, pos)
  elseif byte == MP_STR8 then
    -- str8
    return unpack_str8(data, pos)
  elseif byte == MP_STR16 then
    -- str16
    return unpack_str16(data, pos)
  else
    error("Unsupported MessagePack type: " .. byte)
  end
end

function unpack_map(data, pos, count)
  local result = {}
  pos = pos + 1 -- skip the type byte
  
  for i = 1, count do
    local key, new_pos = unpack_value(data, pos)
    pos = new_pos
    local value, new_pos2 = unpack_value(data, pos)
    pos = new_pos2
    result[key] = value
  end
  
  return result, pos
end

function unpack_str(data, pos, len)
  pos = pos + 1 -- skip the type byte
  if pos + len - 1 > #data then
    error("String extends beyond data")
  end
  local str = string.sub(data, pos, pos + len - 1)
  return str, pos + len
end

function unpack_uint8(data, pos)
  pos = pos + 1 -- skip the type byte
  if pos > #data then
    error("Insufficient data for uint8")
  end
  local value = string.byte(data, pos)
  return value, pos + 1
end

function unpack_uint16(data, pos)
  pos = pos + 1 -- skip the type byte
  if pos + 1 > #data then
    error("Insufficient data for uint16")
  end
  local value = string.unpack(">I2", data, pos)
  return value, pos + 2
end

function unpack_uint32(data, pos)
  pos = pos + 1 -- skip the type byte
  if pos + 3 > #data then
    error("Insufficient data for uint32")
  end
  local value = string.unpack(">I4", data, pos)
  return value, pos + 4
end

function unpack_str8(data, pos)
  pos = pos + 1 -- skip the type byte
  if pos > #data then
    error("Insufficient data for str8 length")
  end
  local len = string.byte(data, pos)
  pos = pos + 1
  if pos + len - 1 > #data then
    error("String extends beyond data")
  end
  local str = string.sub(data, pos, pos + len - 1)
  return str, pos + len
end

function unpack_str16(data, pos)
  pos = pos + 1 -- skip the type byte
  if pos + 1 > #data then
    error("Insufficient data for str16 length")
  end
  local len = string.unpack(">I2", data, pos)
  pos = pos + 2
  if pos + len - 1 > #data then
    error("String extends beyond data")
  end
  local str = string.sub(data, pos, pos + len - 1)
  return str, pos + len
end

return M 
