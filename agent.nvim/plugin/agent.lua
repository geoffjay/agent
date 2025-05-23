-- agent.nvim plugin entry point
-- This file is automatically loaded by Neovim

if vim.g.loaded_agent_nvim then
  return
end
vim.g.loaded_agent_nvim = 1

-- Check minimum Neovim version
if vim.fn.has("nvim-0.8") == 0 then
  vim.api.nvim_err_writeln("agent.nvim requires Neovim >= 0.8")
  return
end

-- Lazy-load the main module
vim.api.nvim_create_user_command("Agent", function(opts)
  require("agent").setup()
  
  if opts.args == "start" then
    require("agent").start()
  elseif opts.args == "stop" then
    require("agent").stop()
  elseif opts.args == "status" then
    require("agent").show_status()
  elseif opts.args == "toggle" then
    require("agent").toggle()
  else
    require("agent").show_status()
  end
end, {
  nargs = "?",
  complete = function()
    return { "start", "stop", "status", "toggle" }
  end,
  desc = "Agent.nvim commands",
})

-- Create highlight groups for the plugin
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "AgentConnected", { fg = "#98C379", bold = true })
    vim.api.nvim_set_hl(0, "AgentDisconnected", { fg = "#E06C75", bold = true })
    vim.api.nvim_set_hl(0, "AgentInfo", { fg = "#61AFEF" })
    vim.api.nvim_set_hl(0, "AgentWarning", { fg = "#E5C07B" })
    vim.api.nvim_set_hl(0, "AgentError", { fg = "#E06C75" })
  end,
})

-- Set initial highlight groups
vim.api.nvim_set_hl(0, "AgentConnected", { fg = "#98C379", bold = true })
vim.api.nvim_set_hl(0, "AgentDisconnected", { fg = "#E06C75", bold = true })
vim.api.nvim_set_hl(0, "AgentInfo", { fg = "#61AFEF" })
vim.api.nvim_set_hl(0, "AgentWarning", { fg = "#E5C07B" })
vim.api.nvim_set_hl(0, "AgentError", { fg = "#E06C75" }) 
