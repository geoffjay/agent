# Agent System Testing Workflow

## Complete Message Flow Testing

This guide walks through testing the complete message flow between the chat TUI and neovim plugin.

## Setup

1. **Start the Agent Service**
   ```bash
   ./agent serve
   ```
   You should see: `Agent service listening on 127.0.0.1:7070`

2. **Start the Chat TUI** (in another terminal)
   ```bash
   ./agent chat
   ```
   You should see the TUI with connection status: `🟢 Connected to agent.nvim`

3. **Connect from Neovim** (in a neovim instance)
   ```vim
   :AgentStart
   ```
   You should see: `[Agent] Agent connected successfully`

## Message Flow Testing

### 1. Chat → Neovim

**From Chat TUI:**
1. Type a message: `Hello from chat interface!`
2. Press `Ctrl+S` to send
3. You should see: `✓ Message sent to agent`

**In Neovim:**
- You should see a notification: `💬 Chat: Hello from chat interface!`

### 2. Neovim → Chat

**From Neovim:**
1. Send a reply: `:AgentReply Hello from Neovim!`
2. You should see: `[Agent] Sent response to chat: Hello from Neovim!`

**In Chat TUI:**
- You should see: `Agent: Hello from Neovim!` (in blue)

### 3. Code Sharing: Neovim → Chat

**From Neovim:**
1. Send current buffer: `:AgentSendBuffer`
2. Or send selection: 
   - Select some text in visual mode
   - Run: `:AgentSendSelection`

**In Chat TUI:**
- You should see: `📝 Received code from Neovim`

### 4. Service Status

**From Chat TUI:**
1. Type: `status`
2. Press `Ctrl+S`

You should see JSON status showing connected clients:
```json
📊 Service Status:
{
  "clients": [
    {
      "id": "127.0.0.1:xxxxx",
      "type": "chat",
      "last_seen": 1705123456
    },
    {
      "id": "127.0.0.1:xxxxx", 
      "type": "nvim",
      "last_seen": 1705123456
    }
  ],
  "client_count": 2,
  "uptime": 1705123456
}
```

## Available Commands

### Chat TUI
- `Ctrl+S`: Send message
- `Ctrl+C`: Quit
- Type `status`: Get service status

### Neovim Plugin
- `:AgentStart`: Connect to service
- `:AgentStop`: Disconnect from service
- `:AgentStatus`: Show connection status
- `:AgentReply <message>`: Send message to chat
- `:AgentSendBuffer`: Send current buffer to chat
- `:AgentSendSelection`: Send visual selection to chat

## Expected Service Logs

When messages are sent, you should see logs like:
```
INFO[...] Client 127.0.0.1:xxxxx identified as: chat
INFO[...] Client 127.0.0.1:xxxxx identified as: nvim
DEBU[...] Received message from 127.0.0.1:xxxxx: type=chat
DEBU[...] Sent message to 127.0.0.1:xxxxx: type=chat, id=1
DEBU[...] Sent message to 127.0.0.1:xxxxx: type=ack, id=1
```

## Troubleshooting

### Chat messages not showing in Neovim
- Ensure you've updated the neovim plugin code (restart neovim or `:source %`)
- Check that the plugin shows "💬 Chat:" notifications
- Verify the service shows both clients as connected

### Neovim messages not showing in Chat
- Ensure you're using `:AgentReply` command (not the old direct send)
- Check the service logs for message routing
- Verify the chat TUI shows "Agent:" messages in blue

### Connection Issues
- Check that the service is running on port 7070
- Verify no firewall blocking connections
- Ensure both clients identify themselves properly

### Message Routing Problems
- Check service logs for client identification
- Verify message types are being routed correctly
- Use the status command to see connected clients

## Quick Demo Script

For automated testing, use:
```bash
./scripts/demo-full-system.sh
```

This will start the service and provide instructions for connecting both clients. 
