-- Toggle a clean buffer view to make copying text easier
local clean_view_enabled = false
local saved_listchars = vim.opt.listchars:get()

function CleanViewToggle()
  local gs_ok, gitsigns = pcall(require, "gitsigns")
  local scope_ok, _ = pcall(require, "mini.indentscope")

  if clean_view_enabled == false then
    clean_view_enabled = true

    -- UI: numbers, gutter, listchars
    vim.opt.number = false
    vim.opt.relativenumber = false
    vim.opt.signcolumn = "no"
    vim.opt.list = false
    vim.wo.list = false

    -- Save/clear listchars
    saved_listchars = vim.opt.listchars:get()

    -- Disable virtual text plugins
    vim.cmd("IBLDisable")
    vim.cmd("TSContextDisable")

    -- Safely disable diagnostics if available
    if vim.diagnostic and vim.diagnostic.disable then
      vim.diagnostic.disable()
    end

    -- Disable mini.indentscope properly
    vim.b.miniindentscope_disable = true
    vim.cmd("doautocmd BufEnter")

    -- Clear all virtual text namespaces
    for _, ns in pairs(vim.api.nvim_get_namespaces()) do
      vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    end

    -- Detach gitsigns
    if gs_ok and type(gitsigns.detach) == "function" then
      gitsigns.detach()
    end

    vim.cmd("silent! redraw")
  else
    clean_view_enabled = false

    -- Re-enable UI
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.signcolumn = "yes"
    vim.opt.list = true
    vim.wo.list = true
    vim.opt.listchars = saved_listchars

    -- Re-enable plugins
    vim.cmd("IBLEnable")
    vim.cmd("TSContextEnable")

    -- Safely enable diagnostics if available
    if vim.diagnostic and vim.diagnostic.enable then
      vim.diagnostic.enable()
    end

    -- Re-enable mini.indentscope
    vim.b.miniindentscope_disable = false
    vim.cmd("doautocmd BufEnter")

    -- Reattach gitsigns
    if gs_ok and type(gitsigns.attach) == "function" then
      gitsigns.attach()
    end
  end
end

-- Keymap
vim.api.nvim_set_keymap('n', '<leader>cv', '<cmd>lua CleanViewToggle()<CR>', {
  noremap = true,
  silent = true,
  desc = "[c]lean [v]iew Toggle"
})

