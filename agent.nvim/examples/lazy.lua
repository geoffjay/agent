-- Example lazy.nvim configuration for agent.nvim

return {
  {
    "your-username/agent.nvim",
    
    -- Lazy loading configuration
    cmd = { 
      "Agent", 
      "AgentStart", 
      "AgentStop", 
      "AgentStatus", 
      "AgentToggle",
      "AgentClear",
    },
    
    -- Key mappings for lazy loading
    keys = {
      { "<leader>at", desc = "Toggle Agent Connection" },
      { "<leader>as", desc = "Send Buffer/Selection to Agent", mode = { "n", "v" } },
      { "<leader>ai", desc = "Show Agent Status" },
      { "<leader>ac", desc = "Clear Agent Messages" },
    },
    
    -- Plugin configuration
    config = function()
      require("agent").setup({
        -- Socket configuration
        socket = {
          host = "127.0.0.1",    -- Agent service host
          port = 7070,           -- Agent service port  
          timeout = 5000,        -- Connection timeout in ms
        },
        
        -- Keybindings (set to false to disable specific bindings)
        keymaps = {
          toggle_agent = "<leader>at",     -- Toggle agent connection
          send_message = "<leader>as",     -- Send buffer/selection to agent
          show_status = "<leader>ai",      -- Show agent status
          clear_messages = "<leader>ac",   -- Clear message history
        },
        
        -- UI configuration
        ui = {
          border = "rounded",              -- Border style: rounded, single, double, none
          width = 80,                      -- Default window width
          height = 20,                     -- Default window height
        },
        
        -- Agent configuration
        agent = {
          auto_start = false,              -- Auto-connect on startup
          debug = false,                   -- Enable debug logging
        },
      })
    end,
    
    -- Optional: dependencies if you have any
    -- dependencies = {},
    
    -- Optional: version constraint
    -- version = "*",
    
    -- Optional: development setup
    -- dev = true,
    -- dir = "~/path/to/local/agent.nvim",
  },
  
  -- Alternative: Minimal configuration
  -- {
  --   "your-username/agent.nvim",
  --   config = true,  -- Use default configuration
  --   cmd = "Agent",
  --   keys = "<leader>a",
  -- },
  
  -- Alternative: Auto-start configuration
  -- {
  --   "your-username/agent.nvim",
  --   event = "VimEnter",  -- Load on startup
  --   config = function()
  --     require("agent").setup({
  --       agent = {
  --         auto_start = true,  -- Auto-connect on startup
  --       },
  --     })
  --   end,
  -- },
} 
