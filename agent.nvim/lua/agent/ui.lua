local M = {}

-- UI state
local state = {
  config = {},
  buffers = {},
  windows = {},
}

-- Setup UI configuration
function M.setup(config)
  state.config = vim.tbl_deep_extend("force", {
    border = "rounded",
    width = 80,
    height = 20,
  }, config or {})
end

-- Create a floating window
function M.create_float(opts)
  opts = opts or {}
  
  local width = opts.width or state.config.width
  local height = opts.height or state.config.height
  
  -- Calculate position to center the window
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Window options
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = opts.border or state.config.border,
    title = opts.title,
    title_pos = "center",
    style = "minimal",
  }
  
  -- Create window
  local win = vim.api.nvim_open_win(buf, opts.enter or false, win_opts)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", opts.filetype or "agent")
  
  -- Set window options
  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "cursorline", true)
  
  return buf, win
end

-- Show information in a floating window
function M.show_info(lines, opts)
  opts = opts or {}
  
  if type(lines) == "string" then
    lines = { lines }
  end
  
  local buf, win = M.create_float({
    title = opts.title or " Agent Info ",
    width = opts.width,
    height = math.max(#lines + 2, 5),
    enter = opts.enter,
  })
  
  -- Set content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
  -- Close on escape or q
  local function close_window()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  
  vim.keymap.set("n", "<Esc>", close_window, { buffer = buf, silent = true })
  vim.keymap.set("n", "q", close_window, { buffer = buf, silent = true })
  
  -- Auto-close after timeout if specified
  if opts.timeout then
    vim.defer_fn(close_window, opts.timeout)
  end
  
  return buf, win
end

-- Show status window
function M.show_status(status_data)
  local lines = {}
  
  if type(status_data) == "table" then
    for _, line in ipairs(status_data) do
      table.insert(lines, line)
    end
  else
    table.insert(lines, tostring(status_data))
  end
  
  M.show_info(lines, {
    title = " Agent Status ",
    enter = false,
    timeout = 3000,
  })
end

-- Show messages window
function M.show_messages(messages)
  local lines = {}
  
  table.insert(lines, "Agent Messages:")
  table.insert(lines, string.rep("-", 50))
  
  if #messages == 0 then
    table.insert(lines, "No messages")
  else
    for i, msg in ipairs(messages) do
      local timestamp = os.date("%H:%M:%S", msg.timestamp)
      table.insert(lines, string.format("[%s] %s", timestamp, msg.type))
      
      if msg.data and msg.data.content then
        -- Split content into multiple lines if needed
        local content_lines = vim.split(msg.data.content, "\n")
        for _, content_line in ipairs(content_lines) do
          table.insert(lines, "  " .. content_line)
        end
      end
      
      if i < #messages then
        table.insert(lines, "")
      end
    end
  end
  
  local buf, win = M.create_float({
    title = " Agent Messages ",
    height = math.min(math.max(#lines + 2, 10), 30),
    enter = true,
  })
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  
  -- Navigation keymaps
  local function close_window()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  
  vim.keymap.set("n", "<Esc>", close_window, { buffer = buf, silent = true })
  vim.keymap.set("n", "q", close_window, { buffer = buf, silent = true })
  vim.keymap.set("n", "j", "j", { buffer = buf, silent = true })
  vim.keymap.set("n", "k", "k", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Down>", "j", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Up>", "k", { buffer = buf, silent = true })
  
  return buf, win
end

-- Show input prompt
function M.show_input(prompt, callback, opts)
  opts = opts or {}
  
  local buf, win = M.create_float({
    title = " " .. (prompt or "Input") .. " ",
    width = opts.width or 60,
    height = 3,
    enter = true,
  })
  
  -- Set prompt line
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { prompt or "Enter input:", "" })
  
  -- Position cursor on second line
  vim.api.nvim_win_set_cursor(win, { 2, 0 })
  
  -- Enter insert mode
  vim.cmd("startinsert")
  
  local function handle_input()
    local lines = vim.api.nvim_buf_get_lines(buf, 1, 2, false)
    local input = lines[1] or ""
    
    -- Close window
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    
    -- Call callback with input
    if callback then
      callback(input)
    end
  end
  
  local function cancel_input()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    
    if callback then
      callback(nil)
    end
  end
  
  -- Keymaps
  vim.keymap.set("i", "<CR>", handle_input, { buffer = buf, silent = true })
  vim.keymap.set("i", "<Esc>", cancel_input, { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", cancel_input, { buffer = buf, silent = true })
  
  return buf, win
end

-- Progress indicator
function M.show_progress(message, callback)
  local chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
  local idx = 1
  
  local buf, win = M.create_float({
    title = " Progress ",
    width = string.len(message) + 10,
    height = 3,
    enter = false,
  })
  
  local timer = vim.loop.new_timer()
  
  local function update_progress()
    if not vim.api.nvim_win_is_valid(win) then
      timer:stop()
      timer:close()
      return
    end
    
    local line = chars[idx] .. " " .. message
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { line })
    
    idx = idx + 1
    if idx > #chars then
      idx = 1
    end
  end
  
  timer:start(0, 100, vim.schedule_wrap(update_progress))
  
  local function stop_progress()
    timer:stop()
    timer:close()
    
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  
  if callback then
    callback(stop_progress)
  end
  
  return stop_progress
end

-- Close all agent windows
function M.close_all()
  for _, win in pairs(state.windows) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  state.windows = {}
end

return M 
