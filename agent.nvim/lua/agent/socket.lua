local M = {}

local uv = vim.loop
local msgpack = require("agent.msgpack")

-- Socket state
local state = {
  config = {},
  socket = nil,
  connected = false,
  callbacks = {},
  message_id = 0,
}

-- Setup socket configuration
function M.setup(config)
  state.config = config or {}
end

-- Connect to the agent service
function M.connect(callback)
  if state.connected then
    if callback then callback(true) end
    return
  end
  
  -- Create TCP socket
  state.socket = uv.new_tcp()
  
  if not state.socket then
    if callback then callback(false, "Failed to create socket") end
    return
  end
  
  -- Connect to the agent service
  state.socket:connect(state.config.host, state.config.port, function(err)
    if err then
      state.connected = false
      if callback then callback(false, err) end
      return
    end
    
    state.connected = true
    
    -- Start reading from the socket
    state.socket:read_start(M.on_read)
    
    if callback then callback(true) end
  end)
end

-- Disconnect from the agent service
function M.disconnect()
  if not state.connected or not state.socket then
    return
  end
  
  state.socket:close()
  state.socket = nil
  state.connected = false
  state.callbacks = {}
end

-- Send message to the agent
function M.send(message, callback)
  if not state.connected or not state.socket then
    if callback then callback(nil, "Not connected") end
    return
  end
  
  -- Add message ID for callback tracking
  state.message_id = state.message_id + 1
  message.id = state.message_id
  
  -- Store callback for response
  if callback then
    state.callbacks[state.message_id] = callback
  end
  
  -- Serialize message using msgpack
  local success, encoded = pcall(msgpack.encode, message)
  if not success then
    if callback then callback(nil, "Failed to encode message: " .. encoded) end
    return
  end
  
  -- Send the message
  state.socket:write(encoded, function(err)
    if err then
      -- Remove callback on error
      state.callbacks[state.message_id] = nil
      if callback then callback(nil, err) end
    end
  end)
end

-- Handle incoming data from socket
function M.on_read(err, data)
  if err then
    vim.schedule(function()
      vim.notify("Socket read error: " .. err, vim.log.levels.ERROR)
    end)
    return
  end
  
  if not data then
    -- Connection closed
    state.connected = false
    vim.schedule(function()
      vim.notify("Agent connection closed", vim.log.levels.WARN)
    end)
    return
  end
  
  -- Decode msgpack data
  local success, decoded = pcall(msgpack.decode, data)
  if not success then
    vim.schedule(function()
      vim.notify("Failed to decode message: " .. decoded, vim.log.levels.ERROR)
    end)
    return
  end
  
  -- Handle the response
  vim.schedule(function()
    M.handle_response(decoded)
  end)
end

-- Handle response from agent
function M.handle_response(response)
  local message_id = response.id
  local callback = state.callbacks[message_id]
  
  if callback then
    -- Remove callback and call it
    state.callbacks[message_id] = nil
    callback(response, nil)
  else
    -- Handle unsolicited messages (like notifications)
    M.handle_notification(response)
  end
end

-- Handle unsolicited messages/notifications
function M.handle_notification(message)
  -- This could be extended to handle different types of notifications
  if message.type == "notification" then
    vim.notify(message.content or "Agent notification", vim.log.levels.INFO)
  elseif message.type == "log" then
    local level = vim.log.levels[string.upper(message.level or "INFO")] or vim.log.levels.INFO
    vim.notify(message.content or "", level)
  end
end

-- Check if connected
function M.is_connected()
  return state.connected
end

-- Get connection info
function M.get_info()
  return {
    connected = state.connected,
    host = state.config.host,
    port = state.config.port,
    pending_callbacks = vim.tbl_count(state.callbacks),
  }
end

return M 
