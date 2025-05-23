# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-01-XX

### Added
- Initial plugin implementation
- TCP socket communication with msgpack serialization
- Fallback to JSON with length prefix when msgpack unavailable
- Real-time agent integration capabilities
- Floating UI for status and information display
- Configurable keybindings with sane defaults
- Support for sending current buffer to agent
- Support for sending visual selection to agent
- Automatic application of edits received from agent
- User commands: `:Agent`, `:AgentStart`, `:AgentStop`, `:AgentStatus`, `:AgentToggle`, `:AgentClear`
- Default keymaps: `<leader>at`, `<leader>as`, `<leader>ai`, `<leader>ac`
- Comprehensive configuration options
- Debug logging support
- Auto-start option for automatic connection on startup
- Progress indicators and status displays
- Error handling and notification system
- Plugin entry point with version checking
- Complete documentation (README, help files, examples)
- Lazy.nvim compatibility and configuration examples
- MIT license

### Features
- **Socket Communication**: TCP socket with msgpack serialization
- **Agent Integration**: Send code and receive edits from autonomous agents
- **Chat Interface Support**: Designed to work with chat-based agent interfaces
- **Task Execution**: Support for agents executing tasks in `xit` format
- **Floating UI**: Beautiful floating windows for all interactions
- **Configurable**: Fully customizable through setup function
- **Lazy Loading**: Efficient loading compatible with modern plugin managers

### Requirements
- Neovim >= 0.8.0
- Agent service running on TCP socket (default: localhost:7070)

## [0.0.1] - 2024-01-XX

### Added
- Project initialization
- Basic plugin structure
- Plan documentation 
