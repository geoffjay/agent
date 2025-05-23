# Agent Chat Subcommand Plan

The `agent` tool is a service that runs in the background and executes tasks on
behalf of the user, by executing on task lists written in the `xit` format.
While fully autonomous agents are the key feature of `agent`, also being able to
run an agent in chat mode with an interface is a goal. In this configuration a
user would run a chat agent, run a chat utility in a terminal that this plan is
meant to address, and then run the agent neovim plugin. The chat would send and
receive messages to the neovim plugin, and the plugin to the chat. This should
be implemented to make code edits within neovim that are performed by an agent
that interfaces with the chat.

The chat subcommand should:

- run when the `agent chat` command is executed
- be implemented in `cmd/chat.go`
- use github.com/charmbracelet/bubbletea for the TUI (terminal user interface)
- use github.com/charmbracelet/lipgloss to style the TUI
- use github.com/charmbracelet/bubbles for additional TUI components, eg. a text area for output
- allow the user to input a multi-line prompt
- communicate with the `agent.nvim` plugin that has been created in the folder of this project with the same name