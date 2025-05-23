# Agent Neovim Plugin Plan

The `agent` tool is a service that runs in the background and executes tasks on
behalf of the user, by executing on task lists written in the `xit` format.
While fully autonomous agents are the key feature of `agent`, also being able to
run an agent in chat mode with an interface is a goal. In this configuration a
user would run a chat agent, run a chat utility in a terminal, and then run the
agent neovim plugin that this plan is meant to address. The chat would send and
receive messages to the neovim plugin, and the plugin to the chat. This should
be implemented to make code edits within neovim that are performed by an agent
that interfaces with the chat.

This plugin must:

- be a neovim plugin written in lua
- provide a messaging interface that is common in neovim and related plugins (I believe this is via socket communication with the API using msgpack)
- define sane defaults for keyboard bindings
- be capable of being configured using typical neovim means (specifically lazy.nvim)
- have all documentation required for installing, configuring, and using the plugin