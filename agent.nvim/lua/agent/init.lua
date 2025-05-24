local M = {}

-- Default configuration
local default_config = {
  -- Socket configuration
  socket = {
    host = "127.0.0.1",
    port = 7070,
    timeout = 5000,
  },
  -- Keybindings
  keymaps = {
    toggle_agent = "<leader>at",
    send_message = "<leader>as",
    show_status = "<leader>ai",
    clear_messages = "<leader>ac",
  },
  -- UI configuration
  ui = {
    border = "rounded",
    width = 80,
    height = 20,
  },
  -- Agent configuration
  agent = {
    auto_start = false,
    debug = false,
  },
}

-- Plugin state
local state = {
  config = {},
  socket = nil,
  connected = false,
  messages = {},
  ui = {
    buf = nil,
    win = nil,
  },
}

-- Load required modules
local socket = require("agent.socket")
local ui = require("agent.ui")
local utils = require("agent.utils")

-- Setup function called by lazy.nvim or similar
function M.setup(opts)
  -- Merge user config with defaults
  state.config = vim.tbl_deep_extend("force", default_config, opts or {})
  
  -- Setup socket communication
  socket.setup(state.config.socket)
  
  -- Setup UI components
  ui.setup(state.config.ui)
  
  -- Setup keymaps
  M.setup_keymaps()
  
  -- Setup autocmds
  M.setup_autocmds()
  
  -- Auto-start if configured
  if state.config.agent.auto_start then
    M.start()
  end
  
  -- Setup user commands
  M.setup_commands()
end

-- Setup keymaps
function M.setup_keymaps()
  local keymaps = state.config.keymaps
  
  vim.keymap.set("n", keymaps.toggle_agent, M.toggle, { desc = "Toggle Agent" })
  vim.keymap.set("n", keymaps.send_message, M.send_current_buffer, { desc = "Send Current Buffer to Agent" })
  vim.keymap.set("n", keymaps.show_status, M.show_status, { desc = "Show Agent Status" })
  vim.keymap.set("n", keymaps.clear_messages, M.clear_messages, { desc = "Clear Agent Messages" })
  
  -- Visual mode keymap for sending selection
  vim.keymap.set("v", keymaps.send_message, M.send_selection, { desc = "Send Selection to Agent" })
end

-- Setup autocmds
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("Agent", { clear = true })
  
  -- Auto-connect on VimEnter if auto_start is enabled
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      if state.config.agent.auto_start then
        M.start()
      end
    end,
  })
  
  -- Cleanup on VimLeave
  vim.api.nvim_create_autocmd("VimLeave", {
    group = group,
    callback = function()
      M.stop()
    end,
  })
end

-- Setup user commands
function M.setup_commands()
  vim.api.nvim_create_user_command("AgentStart", M.start, { desc = "Start the agent connection" })
  vim.api.nvim_create_user_command("AgentStop", M.stop, { desc = "Stop the agent connection" })
  vim.api.nvim_create_user_command("AgentStatus", M.show_status, { desc = "Show agent status" })
  vim.api.nvim_create_user_command("AgentToggle", M.toggle, { desc = "Toggle agent connection" })
  vim.api.nvim_create_user_command("AgentClear", M.clear_messages, { desc = "Clear agent messages" })
  vim.api.nvim_create_user_command("AgentSendBuffer", M.send_current_buffer, { desc = "Send current buffer to agent" })
  vim.api.nvim_create_user_command("AgentSendSelection", M.send_selection, { desc = "Send visual selection to agent" })
  vim.api.nvim_create_user_command("AgentReply", function(opts)
    M.send_chat_response(opts.args)
  end, { nargs = "+", desc = "Send a message to the chat interface" })
end

-- Start the agent connection
function M.start()
  if state.connected then
    utils.notify("Agent is already connected", vim.log.levels.INFO)
    return
  end
  
  socket.connect(function(success, err)
    if success then
      state.connected = true
      utils.notify("Agent connected successfully", vim.log.levels.INFO)
    else
      utils.notify("Failed to connect to agent: " .. (err or "unknown error"), vim.log.levels.ERROR)
    end
  end)
end

-- Stop the agent connection
function M.stop()
  if not state.connected then
    utils.notify("Agent is not connected", vim.log.levels.INFO)
    return
  end
  
  socket.disconnect()
  state.connected = false
  utils.notify("Agent disconnected", vim.log.levels.INFO)
end

-- Toggle agent connection
function M.toggle()
  if state.connected then
    M.stop()
  else
    M.start()
  end
end

-- Send current buffer to agent
function M.send_current_buffer()
  if not state.connected then
    utils.notify("Agent is not connected", vim.log.levels.WARN)
    return
  end
  
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  local filename = vim.api.nvim_buf_get_name(buf)
  
  M.send_message({
    type = "buffer",
    filename = filename,
    content = content,
    cursor_pos = vim.api.nvim_win_get_cursor(0),
  })
end

-- Send visual selection to agent
function M.send_selection()
  if not state.connected then
    utils.notify("Agent is not connected", vim.log.levels.WARN)
    return
  end
  
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
  
  -- Handle partial line selection
  if #lines > 0 then
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
    else
      lines[1] = string.sub(lines[1], start_pos[3])
      lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    end
  end
  
  local content = table.concat(lines, "\n")
  local filename = vim.api.nvim_buf_get_name(0)
  
  M.send_message({
    type = "selection",
    filename = filename,
    content = content,
    start_pos = { start_pos[2], start_pos[3] },
    end_pos = { end_pos[2], end_pos[3] },
  })
end

-- Send response message to chat interface
function M.send_chat_response(message)
  if not state.connected then
    utils.notify("Agent is not connected", vim.log.levels.WARN)
    return
  end
  
  M.send_message({
    type = "message",
    content = {
      content = message,
      source = "neovim"
    },
  })
  
  utils.notify("Sent response to chat: " .. message, vim.log.levels.INFO)
end

-- Send message to agent
function M.send_message(message)
  if not state.connected then
    utils.notify("Agent is not connected", vim.log.levels.WARN)
    return
  end
  
  socket.send(message, function(response, err)
    if err then
      utils.notify("Failed to send message: " .. err, vim.log.levels.ERROR)
    else
      M.handle_response(response)
    end
  end)
end

-- Handle response from agent
function M.handle_response(response)
  table.insert(state.messages, {
    timestamp = os.time(),
    type = "response",
    data = response,
  })
  
  if response.type == "edit" then
    M.apply_edit(response)
  elseif response.type == "message" then
    utils.notify(response.content, vim.log.levels.INFO)
  elseif response.type == "error" then
    utils.notify(response.content, vim.log.levels.ERROR)
  end
end

-- Record incoming message (for tracking purposes)
function M.record_message(message, message_type)
  table.insert(state.messages, {
    timestamp = os.time(),
    type = message_type or "incoming",
    data = message,
  })
end

-- Apply edit from agent
function M.apply_edit(edit_data)
  if not edit_data.filename or not edit_data.content then
    utils.notify("Invalid edit data received", vim.log.levels.ERROR)
    return
  end
  
  -- Find or create buffer for the file
  local buf = vim.fn.bufnr(edit_data.filename)
  if buf == -1 then
    buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(buf, edit_data.filename)
  end
  
  -- Apply the edit
  local lines = vim.split(edit_data.content, "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Save if specified
  if edit_data.save then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("write")
    end)
  end
  
  utils.notify("Applied edit to " .. edit_data.filename, vim.log.levels.INFO)
end

-- Show agent status
function M.show_status()
  local status = {
    "Agent Status:",
    "Connected: " .. (state.connected and "Yes" or "No"),
    "Socket: " .. state.config.socket.host .. ":" .. state.config.socket.port,
    "Messages: " .. #state.messages,
  }
  
  ui.show_info(status)
end

-- Clear messages
function M.clear_messages()
  state.messages = {}
  utils.notify("Agent messages cleared", vim.log.levels.INFO)
end

-- Get current state (for debugging)
function M.get_state()
  return state
end

return M 
