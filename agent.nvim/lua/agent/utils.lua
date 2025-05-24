local M = {}

-- Notification function with consistent formatting
function M.notify(message, level, opts)
  opts = opts or {}
  level = level or vim.log.levels.INFO
  
  local title = opts.title or "Agent"
  local formatted_message = string.format("[%s] %s", title, message)
  
  -- Use vim.schedule to ensure we're in the correct context
  vim.schedule(function()
    vim.notify(formatted_message, level, {
      title = title,
      timeout = opts.timeout,
    })
  end)
end

-- Debug logging (only shown when debug is enabled)
function M.debug(message, data)
  -- Check if debug mode is enabled in config
  local agent = require("agent")
  local state = agent.get_state()
  
  if state.config and state.config.agent and state.config.agent.debug then
    local debug_msg = message
    if data then
      debug_msg = debug_msg .. ": " .. vim.inspect(data)
    end
    M.notify(debug_msg, vim.log.levels.DEBUG, { title = "Agent Debug" })
  end
end

-- Error handling with stack trace
function M.handle_error(err, context)
  local error_msg = context and (context .. ": " .. err) or err
  
  -- Add stack trace if available
  if debug.traceback then
    error_msg = error_msg .. "\n" .. debug.traceback()
  end
  
  M.notify(error_msg, vim.log.levels.ERROR)
  
  -- Log to vim's messages as well
  vim.api.nvim_err_writeln("Agent Error: " .. error_msg)
end

-- Safe function execution with error handling
function M.safe_call(func, ...)
  local ok, result = pcall(func, ...)
  if not ok then
    M.handle_error(result, "Safe call failed")
    return nil, result
  end
  return result
end

-- Get current buffer info
function M.get_buffer_info(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  
  return {
    id = buf,
    name = vim.api.nvim_buf_get_name(buf),
    filetype = vim.api.nvim_buf_get_option(buf, "filetype"),
    modified = vim.api.nvim_buf_get_option(buf, "modified"),
    line_count = vim.api.nvim_buf_line_count(buf),
    cursor_pos = vim.api.nvim_win_get_cursor(0),
  }
end

-- Get visual selection
function M.get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  if start_pos[1] == 0 or end_pos[1] == 0 then
    return nil
  end
  
  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
  
  if #lines == 0 then
    return nil
  end
  
  -- Handle partial line selection
  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
  else
    lines[1] = string.sub(lines[1], start_pos[3])
    lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
  end
  
  return {
    content = table.concat(lines, "\n"),
    start_pos = { start_pos[2], start_pos[3] },
    end_pos = { end_pos[2], end_pos[3] },
    lines = lines,
  }
end

-- File operations
function M.file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "file"
end

function M.dir_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "directory"
end

function M.read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil, "Could not open file: " .. path
  end
  
  local content = file:read("*all")
  file:close()
  
  return content
end

function M.write_file(path, content)
  local file = io.open(path, "w")
  if not file then
    return false, "Could not open file for writing: " .. path
  end
  
  file:write(content)
  file:close()
  
  return true
end

-- String utilities
function M.trim(str)
  return str:match("^%s*(.-)%s*$")
end

function M.split(str, delimiter)
  delimiter = delimiter or "%s+"
  local result = {}
  for part in str:gmatch("([^" .. delimiter .. "]+)") do
    table.insert(result, part)
  end
  return result
end

function M.starts_with(str, prefix)
  return string.sub(str, 1, string.len(prefix)) == prefix
end

function M.ends_with(str, suffix)
  return string.sub(str, -string.len(suffix)) == suffix
end

-- Table utilities
function M.table_merge(t1, t2)
  local result = vim.deepcopy(t1)
  for k, v in pairs(t2) do
    result[k] = v
  end
  return result
end

function M.table_has_key(tbl, key)
  return tbl[key] ~= nil
end

function M.table_keys(tbl)
  local keys = {}
  for k, _ in pairs(tbl) do
    table.insert(keys, k)
  end
  return keys
end

-- Validation utilities
function M.validate_config(config, schema)
  local errors = {}
  
  for key, spec in pairs(schema) do
    local value = config[key]
    local required = spec.required or false
    local type_check = spec.type
    local validator = spec.validator
    
    -- Check if required field is present
    if required and value == nil then
      table.insert(errors, "Missing required field: " .. key)
    end
    
    -- Check type if value is present
    if value ~= nil and type_check and type(value) ~= type_check then
      table.insert(errors, string.format("Field '%s' must be of type %s, got %s", key, type_check, type(value)))
    end
    
    -- Run custom validator if provided
    if value ~= nil and validator then
      local valid, err = validator(value)
      if not valid then
        table.insert(errors, string.format("Field '%s' validation failed: %s", key, err or "unknown error"))
      end
    end
  end
  
  return #errors == 0, errors
end

-- Time utilities
function M.timestamp()
  return os.time()
end

function M.format_time(timestamp)
  return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

function M.time_ago(timestamp)
  local now = os.time()
  local diff = now - timestamp
  
  if diff < 60 then
    return diff .. " seconds ago"
  elseif diff < 3600 then
    return math.floor(diff / 60) .. " minutes ago"
  elseif diff < 86400 then
    return math.floor(diff / 3600) .. " hours ago"
  else
    return math.floor(diff / 86400) .. " days ago"
  end
end

-- Plugin info
function M.get_plugin_info()
  local plugin_path = debug.getinfo(1, "S").source:sub(2)
  local plugin_dir = vim.fn.fnamemodify(plugin_path, ":h:h:h")
  
  return {
    name = "agent.nvim",
    version = "0.1.0",
    path = plugin_dir,
    lua_version = _VERSION,
    nvim_version = vim.version(),
  }
end

return M 
