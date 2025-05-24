#!/bin/bash

# Debug script for message flow testing

echo "Debug Message Flow Testing"
echo "========================="
echo
echo "This script starts the agent service with verbose debug logging"
echo "to help diagnose message routing issues."
echo
echo "What you'll see in the logs:"
echo "1. Client connections and identification"
echo "2. Message reception with full content"
echo "3. Message routing decisions and targets"
echo "4. Message sending to specific clients"
echo
echo "Testing steps after starting this:"
echo "1. In another terminal: ./agent chat"
echo "2. In neovim: :AgentStart"
echo "3. Send a message from chat TUI"
echo "4. Watch the logs below for message flow"
echo
echo "Press Enter to start the service with debug logging..."
read

echo "Starting agent service with verbose logging..."
./agent serve --verbose 
