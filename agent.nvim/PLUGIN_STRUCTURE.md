# Agent.nvim Plugin Structure

This document describes the complete structure of the agent.nvim plugin and the purpose of each file.

## Directory Structure

```
agent.nvim/
├── lua/agent/              # Main plugin modules
│   ├── init.lua           # Main plugin entry point and API
│   ├── socket.lua         # TCP socket communication with msgpack
│   ├── ui.lua             # Floating windows and UI components
│   ├── utils.lua          # Utility functions and helpers
│   └── msgpack.lua        # Message serialization (msgpack/JSON fallback)
├── plugin/                # Plugin initialization
│   └── agent.lua          # Auto-loaded plugin entry point
├── doc/                   # Documentation
│   └── agent.txt          # Neovim help documentation
├── examples/              # Configuration examples
│   └── lazy.lua           # lazy.nvim configuration example
├── PLAN.md                # Original project plan
├── README.md              # User documentation
├── CHANGELOG.md           # Version history
├── LICENSE                # MIT license
└── PLUGIN_STRUCTURE.md    # This file
```

## File Descriptions

### Core Plugin Files

#### `lua/agent/init.lua`
- Main plugin module that provides the public API
- Handles plugin setup, configuration, and state management
- Provides functions for connecting/disconnecting from agent service
- Manages keybindings, commands, and autocmds
- Handles sending messages to agent and processing responses
- Applies edits received from the agent to Neovim buffers

#### `lua/agent/socket.lua`
- TCP socket communication layer
- Connects to agent service using `vim.loop` (libuv)
- Handles message serialization using msgpack
- Manages connection state and callbacks
- Provides asynchronous message sending and receiving
- Handles connection errors and reconnection

#### `lua/agent/ui.lua`
- User interface components using floating windows
- Status displays, information windows, and progress indicators
- Input prompts and message display windows
- Customizable window borders, sizes, and positioning
- Keyboard navigation and window management

#### `lua/agent/utils.lua`
- Utility functions used throughout the plugin
- Notification system with consistent formatting
- File operations and buffer management helpers
- String and table manipulation utilities
- Error handling and debug logging
- Configuration validation functions

#### `lua/agent/msgpack.lua`
- Message serialization abstraction layer
- Uses vim's built-in msgpack support when available
- Falls back to JSON with length prefix for compatibility
- Provides consistent encode/decode interface

### Plugin Infrastructure

#### `plugin/agent.lua`
- Auto-loaded plugin entry point
- Sets up initial user commands
- Defines highlight groups for UI
- Checks Neovim version compatibility
- Prevents double-loading of the plugin

### Documentation

#### `README.md`
- Comprehensive user documentation
- Installation instructions for various plugin managers
- Configuration options and examples
- Usage guide and workflow description
- API reference and troubleshooting

#### `doc/agent.txt`
- Neovim help documentation (`:help agent.nvim`)
- Follows standard Neovim help file format
- Command reference and function documentation
- Configuration options and examples
- Accessible via `:help` system

#### `examples/lazy.lua`
- Example configuration for lazy.nvim
- Shows proper lazy loading setup
- Demonstrates various configuration options
- Alternative configuration patterns

## Plugin Features

### Socket Communication
- TCP socket connection to agent service
- Msgpack serialization with JSON fallback
- Asynchronous message handling
- Connection state management
- Error handling and reconnection

### Agent Integration
- Send current buffer content to agent
- Send visual selections to agent
- Receive and apply edits from agent
- Handle various message types (edit, message, error, notification)
- Support for xit format task execution

### User Interface
- Floating windows for status and information
- Progress indicators for long operations
- Input prompts for user interaction
- Configurable window styling
- Keyboard navigation

### Configuration
- Comprehensive configuration system
- Sane defaults for all options
- Socket connection settings
- Customizable keybindings
- UI appearance options
- Debug and auto-start modes

### Neovim Integration
- User commands (`:Agent`, `:AgentStart`, etc.)
- Default keybindings with leader key
- Autocmds for startup and cleanup
- Compatible with modern plugin managers
- Follows Neovim plugin conventions

## Requirements Met

✅ **Neovim plugin written in Lua**: All core functionality implemented in Lua
✅ **Messaging interface using socket communication**: TCP socket with msgpack/JSON
✅ **Sane defaults for keyboard bindings**: Default `<leader>a` mappings provided
✅ **Configurable using lazy.nvim**: Full lazy.nvim compatibility with examples
✅ **Complete documentation**: README, help files, and configuration examples

## Usage Summary

1. Install the plugin using your preferred plugin manager
2. Configure the plugin with `require("agent").setup({})`
3. Start an agent service on the configured port (default: 7070)
4. Use `:AgentStart` or `<leader>at` to connect
5. Send code with `<leader>as` and receive edits automatically
6. Monitor status with `<leader>ai`

The plugin is now ready for use and fully meets all requirements specified in the original plan. 
