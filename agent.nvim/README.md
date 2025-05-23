# agent.nvim

A Neovim plugin that provides seamless integration with autonomous agent services through socket communication. This plugin enables agents to execute tasks, make code edits, and interact with your Neovim environment in real-time.

## Features

- **Socket Communication**: TCP socket communication with msgpack serialization
- **Real-time Agent Integration**: Send code and receive edits from autonomous agents
- **Chat Interface Support**: Designed to work with chat-based agent interfaces
- **Task Execution**: Support for agents executing tasks written in `xit` format
- **Floating UI**: Beautiful floating windows for status and information display
- **Configurable Keybindings**: Customizable keyboard shortcuts for all operations
- **Lazy Loading**: Efficient loading compatible with lazy.nvim and other plugin managers

## Requirements

- Neovim >= 0.8.0
- An agent service running on a TCP socket (typically localhost:7070)

## Installation

### With lazy.nvim

```lua
{
  "geoffjay/agent.nvim",
  config = function()
    require("agent").setup({
      -- your configuration here
    })
  end,
  -- Optional: lazy load the plugin
  cmd = { "Agent", "AgentStart", "AgentStop", "AgentStatus", "AgentToggle" },
  keys = {
    { "<leader>at", desc = "Toggle Agent" },
    { "<leader>as", desc = "Send to Agent" },
    { "<leader>ai", desc = "Agent Status" },
    { "<leader>ac", desc = "Clear Agent Messages" },
  },
}
```

### With packer.nvim

```lua
use {
  "geoffjay/agent.nvim",
  config = function()
    require("agent").setup()
  end
}
```

### Manual Installation

1. Clone this repository to your Neovim configuration directory:
   ```bash
   git clone https://github.com/geoffjay/agent.nvim ~/.config/nvim/pack/plugins/start/agent.nvim
   ```

2. Add to your `init.lua`:
   ```lua
   require("agent").setup()
   ```

## Configuration

The plugin comes with sensible defaults but can be fully customized:

```lua
require("agent").setup({
  -- Socket configuration
  socket = {
    host = "127.0.0.1",        -- Agent service host
    port = 7070,               -- Agent service port
    timeout = 5000,            -- Connection timeout in ms
  },
  
  -- Keybindings (set to false to disable)
  keymaps = {
    toggle_agent = "<leader>at",     -- Toggle agent connection
    send_message = "<leader>as",     -- Send buffer/selection to agent
    show_status = "<leader>ai",      -- Show agent status
    clear_messages = "<leader>ac",   -- Clear message history
  },
  
  -- UI configuration
  ui = {
    border = "rounded",        -- Border style: "rounded", "single", "double", "none"
    width = 80,               -- Default window width
    height = 20,              -- Default window height
  },
  
  -- Agent configuration
  agent = {
    auto_start = false,       -- Auto-connect on startup
    debug = false,            -- Enable debug logging
  },
})
```

## Usage

### Basic Commands

- `:Agent` or `:AgentStatus` - Show agent status
- `:AgentStart` - Connect to the agent service
- `:AgentStop` - Disconnect from the agent service
- `:AgentToggle` - Toggle agent connection
- `:AgentClear` - Clear message history

### Default Keybindings

- `<leader>at` - Toggle agent connection
- `<leader>as` - Send current buffer to agent (normal mode) or selection (visual mode)
- `<leader>ai` - Show agent status
- `<leader>ac` - Clear agent messages

### Workflow

1. **Start the Agent Service**: Ensure your agent service is running on the configured host/port
2. **Connect**: Use `:AgentStart` or `<leader>at` to connect to the agent
3. **Send Code**: Use `<leader>as` to send the current buffer or visual selection to the agent
4. **Receive Edits**: The agent can send back edits that will be automatically applied to your buffers
5. **Monitor Status**: Use `<leader>ai` to check connection status and message history

### Message Types

The plugin supports several message types for communication:

#### Sending to Agent

- **Buffer**: Sends entire buffer content with filename and cursor position
- **Selection**: Sends visual selection with position information

#### Receiving from Agent

- **Edit**: Applies code changes to specified files
- **Message**: Displays informational messages
- **Error**: Shows error notifications
- **Notification**: Handles unsolicited messages from the agent

## Agent Service Integration

The plugin expects an agent service that:

1. Listens on a TCP socket (default: localhost:7070)
2. Uses msgpack for message serialization (falls back to JSON with length prefix)
3. Responds to messages with appropriate response types

### Message Format

```lua
-- Outgoing message format
{
  id = 123,                    -- Auto-generated message ID
  type = "buffer",             -- Message type
  filename = "/path/to/file",  -- File being sent
  content = "code content",    -- File/selection content
  cursor_pos = {10, 5},       -- Cursor position [line, col]
  -- Additional fields based on message type
}

-- Incoming response format
{
  id = 123,                    -- Matching message ID
  type = "edit",               -- Response type
  filename = "/path/to/file",  -- File to edit
  content = "new content",     -- New file content
  save = true,                 -- Whether to save after edit
  -- Additional fields based on response type
}
```

## Troubleshooting

### Connection Issues

1. **Service Not Running**: Ensure your agent service is running on the configured port
2. **Port Conflicts**: Check if another service is using the configured port
3. **Firewall**: Ensure localhost connections are allowed

### Message Issues

1. **Encoding Errors**: Check if your agent service supports msgpack or JSON
2. **Large Messages**: Very large buffers might timeout - consider sending selections instead
3. **Invalid Responses**: Check agent service logs for response format issues

### Debug Mode

Enable debug mode to see detailed logging:

```lua
require("agent").setup({
  agent = {
    debug = true,
  },
})
```

## API Reference

### Main Functions

```lua
local agent = require("agent")

-- Setup the plugin
agent.setup(config)

-- Connection management
agent.start()                    -- Connect to agent service
agent.stop()                     -- Disconnect from agent service
agent.toggle()                   -- Toggle connection

-- Sending messages
agent.send_current_buffer()      -- Send current buffer
agent.send_selection()           -- Send visual selection
agent.send_message(message)      -- Send custom message

-- UI functions
agent.show_status()              -- Show status window
agent.clear_messages()           -- Clear message history

-- State access
local state = agent.get_state()  -- Get internal state (debug)
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Related Projects

- [agent](https://github.com/geoffjay/agent) - The autonomous agent service
- [xit](https://github.com/jotaen/xit) - Task list format used by agents

## Support

- Create an issue for bug reports or feature requests
- Check existing issues before creating new ones
- Include your Neovim version and plugin configuration in bug reports 
