# Agent Chat Interface

The `agent chat` command provides a terminal user interface (TUI) for interacting with an AI agent and communicating with the `agent.nvim` plugin.

## Features

- **Beautiful TUI**: Built with Charm's Bubbletea framework for a responsive and attractive interface
- **Socket Communication**: Connects to the `agent.nvim` plugin via TCP socket on port 7070
- **Multi-line Input**: Supports multi-line message composition
- **Real-time Messaging**: Send and receive messages in real-time
- **Auto-reconnection**: Automatically attempts to reconnect if the connection is lost
- **Message Types**: Handles various message types including chat messages, notifications, edits, and errors

## Usage

### Starting the Chat Interface

```bash
agent chat
```

### Keyboard Controls

- **Ctrl+S**: Send the current message
- **Ctrl+C**: Quit the chat interface
- **Normal text editing**: Type your message in the text area

### Connection Status

The interface displays the connection status at the top:
- 🟢 **Connected to agent.nvim**: Successfully connected to the plugin
- 🔴 **Disconnected**: Not connected, attempting to reconnect automatically

## Message Types

The chat interface handles several types of messages:

### User Messages
Messages you send to the agent appear in green with the "You:" prefix.

### Agent Responses
Agent responses appear in blue with the "Agent:" prefix.

### Notifications
System notifications appear in yellow with a 📢 icon.

### Code Edits
When the agent applies code edits, you'll see a status message with a ✏️ icon.

### Errors
Error messages appear in red with a ❌ icon.

## Communication Protocol

The chat interface communicates with the `agent.nvim` plugin using:

- **Protocol**: TCP socket connection
- **Port**: 7070 (default)
- **Serialization**: MessagePack with JSON fallback
- **Message Format**:
  ```json
  {
    "id": 1,
    "type": "chat",
    "content": {
      "type": "user_message",
      "content": "Your message here"
    }
  }
  ```

## Testing

To test the chat interface without the full agent.nvim setup, you can use the provided test server:

```bash
# Terminal 1: Start the test server
go run examples/test-server.go

# Terminal 2: Start the chat interface
./agent chat
```

The test server simulates the agent.nvim plugin and provides echo responses and test notifications.

## Integration with agent.nvim

When used with the actual `agent.nvim` plugin:

1. The plugin listens on port 7070 for incoming connections
2. The chat interface connects and maintains a persistent connection
3. Messages sent through the chat are forwarded to the AI agent
4. Agent responses, code edits, and notifications are displayed in real-time
5. Code edits are applied directly to your Neovim buffers

## Styling and Themes

The interface uses a modern color scheme:

- **Purple**: Titles and borders
- **Green**: User messages
- **Blue**: Agent responses
- **Yellow**: General messages and notifications
- **Red**: Errors
- **Gray**: Status information

The interface is responsive and adapts to your terminal size automatically.

## Troubleshooting

### Connection Issues

If you see "🔴 Disconnected" status:

1. Make sure the `agent.nvim` plugin is running and listening on port 7070
2. Check that no firewall is blocking the connection
3. Verify the plugin is properly configured in your Neovim setup

### Message Formatting Issues

If messages appear garbled or with raw JSON:

1. This may indicate a version mismatch between the chat interface and plugin
2. Check that both are using compatible message formats
3. The interface will display raw JSON for debugging purposes when needed

### Performance Issues

For large conversations:

1. Use the clear functionality (Ctrl+C and restart) to reset the message history
2. The interface automatically scrolls to show the latest messages
3. Consider the terminal size if text appears cramped 
