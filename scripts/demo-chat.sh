#!/bin/bash

# Demo script for the agent chat interface

echo "Agent Chat Interface Demo"
echo "========================="
echo
echo "This script will:"
echo "1. Build the agent binary"
echo "2. Build the test server"
echo "3. Start the test server in the background"
echo "4. Launch the chat interface"
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

echo "Building test server..."
go build -o test-server examples/test-server.go
if [ $? -ne 0 ]; then
    echo "Failed to build test server"
    exit 1
fi

# Start test server in background
echo "Starting test server on port 7070..."
./test-server &
SERVER_PID=$!

# Give server time to start
sleep 2

echo "Starting chat interface..."
echo "Use Ctrl+S to send messages, Ctrl+C to quit"
echo

# Start chat interface
./agent chat

# Cleanup: kill the test server when chat interface exits
echo
echo "Cleaning up..."
kill $SERVER_PID 2>/dev/null
echo "Demo completed." 
