local M = {}

local uv = vim.loop
local msgpack = require("agent.framed_msgpack")

-- Socket state
local state = {
  config = {},
  socket = nil,
  connected = false,
  callbacks = {},
  message_id = 0,
  buffer = "", -- TCP stream buffer for handling partial frames
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
      vim.schedule(function()
        vim.notify("Socket connection failed: " .. err, vim.log.levels.ERROR)
      end)
      if callback then callback(false, err) end
      return
    end
    
    vim.schedule(function()
      vim.notify("Socket connected successfully to " .. state.config.host .. ":" .. state.config.port, vim.log.levels.INFO)
    end)
    
    state.connected = true
    
    -- Start reading from the socket
    state.socket:read_start(M.on_read)
    
    -- Send client identification (with small delay to ensure connection is ready)
    vim.defer_fn(function()
      local identify_msg = {
        id = 1,
        type = "identify",
        content = {
          client_type = "nvim"
        }
      }
      
      -- Send identification message
      vim.schedule(function()
        vim.notify("MessagePack available: " .. tostring(msgpack.is_native()), vim.log.levels.INFO)
        vim.notify("Encoding message: " .. vim.inspect(identify_msg), vim.log.levels.INFO)
      end)
      
      local success, encoded = pcall(msgpack.encode, identify_msg)
      if success then
        -- Add framing: 4-byte length prefix + msgpack data (big-endian)
        local length = #encoded
        local length_bytes = string.char(
          math.floor(length / 16777216) % 256,  -- >> 24
          math.floor(length / 65536) % 256,     -- >> 16
          math.floor(length / 256) % 256,       -- >> 8
          length % 256
        )
        local frame = length_bytes .. encoded
        
        vim.schedule(function()
          vim.notify("Sending identification message: " .. vim.inspect(identify_msg), vim.log.levels.INFO)
        end)
        state.socket:write(frame, function(err)
          vim.schedule(function()
            if err then
              vim.notify("Failed to send identification: " .. err, vim.log.levels.ERROR)
            else
              vim.notify("Identification message sent successfully (" .. #frame .. " bytes framed)", vim.log.levels.INFO)
            end
          end)
        end)
      else
        vim.schedule(function()
          vim.notify("Failed to encode identification message: " .. tostring(encoded), vim.log.levels.ERROR)
          vim.notify("Message was: " .. vim.inspect(identify_msg), vim.log.levels.ERROR)
        end)
      end
    end, 100) -- 100ms delay
    
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
  state.buffer = "" -- Clear the TCP buffer
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
  
  -- Add framing: 4-byte length prefix + msgpack data (big-endian)
  local length = #encoded
  local length_bytes = string.char(
    math.floor(length / 16777216) % 256,  -- >> 24
    math.floor(length / 65536) % 256,     -- >> 16
    math.floor(length / 256) % 256,       -- >> 8
    length % 256
  )
  local frame = length_bytes .. encoded
  
  -- Send the framed message
  state.socket:write(frame, function(err)
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
  
  -- Accumulate data in buffer
  state.buffer = state.buffer .. data
  
  -- Process complete frames from buffer
  while #state.buffer >= 4 do
    -- Read frame length (big-endian 4 bytes)
    local b1, b2, b3, b4 = string.byte(state.buffer, 1, 4)
    local length = b1 * 16777216 + b2 * 65536 + b3 * 256 + b4  -- << 24, << 16, << 8, << 0
    
    -- Check if we have the complete frame
    if #state.buffer < 4 + length then
      -- Need more data for complete frame
      break
    end
    
    -- Extract the frame data
    local frame_data = string.sub(state.buffer, 5, 4 + length)
    
    -- Remove processed frame from buffer
    state.buffer = string.sub(state.buffer, 5 + length)
    
    -- Decode the frame
    local success, decoded = pcall(msgpack.unpack, frame_data)
    if success then
      -- Handle the response
      vim.schedule(function()
        M.handle_response(decoded)
      end)
    else
      vim.schedule(function()
        vim.notify("Failed to decode framed message: " .. decoded, vim.log.levels.ERROR)
      end)
    end
  end
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
  -- Record the message for tracking
  local agent = require("agent")
  if agent and agent.record_message then
    agent.record_message(message, "notification")
  end
  
  -- This could be extended to handle different types of notifications
  if message.type == "notification" then
    vim.notify(message.content or "Agent notification", vim.log.levels.INFO)
  elseif message.type == "log" then
    local level = vim.log.levels[string.upper(message.level or "INFO")] or vim.log.levels.INFO
    vim.notify(message.content or "", level)
  elseif message.type == "chat" then
    -- Handle chat messages from the chat TUI
    local content = ""
    if type(message.content) == "table" and message.content.content then
      content = message.content.content
    elseif type(message.content) == "string" then
      content = message.content
    else
      content = vim.inspect(message.content)
    end
    
    vim.schedule(function()
      vim.notify("💬 Chat: " .. content, vim.log.levels.INFO, {
        title = "Agent Chat",
        timeout = 5000,
      })
    end)
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
