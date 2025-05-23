#!/bin/bash

# Demo script for the complete agent system with service broker

echo "Agent Complete System Demo"
echo "=========================="
echo
echo "This script demonstrates the complete agent system architecture:"
echo "1. Agent Service Broker (handles message routing)"
echo "2. Agent Chat TUI (terminal interface)"  
echo "3. agent.nvim Plugin (connects from neovim)"
echo
echo "Architecture:"
echo "  Chat TUI ←→ Agent Service ←→ agent.nvim Plugin"
echo "            (port 7070)"
echo
echo "Steps:"
echo "1. Start the agent service broker"
echo "2. Start the chat interface"
echo "3. Open neovim and run :AgentStart"
echo "4. Send messages between chat and neovim"
echo
echo "Press Enter to continue or Ctrl+C to abort..."
read

# Build binaries
echo "Building agent binary..."
go build -o agent .
if [ $? -ne 0 ]; then
    echo "Failed to build agent binary"
    exit 1
fi

# Start agent service in background
echo "Starting agent service broker on port 7070..."
./agent serve &
SERVICE_PID=$!

# Give service time to start
sleep 2

echo "Agent service started (PID: $SERVICE_PID)"
echo
echo "Now you can:"
echo "1. In another terminal, run: ./agent chat"
echo "2. In neovim, run: :AgentStart"
echo "3. Send messages between them!"
echo
echo "The service will route messages between the chat interface and neovim."
echo
echo "Service status can be checked with: curl http://localhost:7070/status"
echo "Or by sending a 'status' message from the chat interface."
echo
echo "Press Enter to stop the service..."
read

# Cleanup: kill the service
echo "Stopping agent service..."
kill $SERVICE_PID 2>/dev/null
echo "Demo completed." 
