-- Toggle to get rid of all the virtualtext so that the buffer can
-- be more coducive to copying 
local clean_view_enabled = false
local saved_listchars = vim.opt.listchars:get()
function CleanViewToggle()
  local gs_ok, gitsigns = pcall(require, "gitsigns")
  local scope_ok, indentscope = pcall(require, "mini.indentscope")
  local ns_id = vim.api.nvim_get_namespaces()["MiniIndentscope"]

  if not clean_view_enabled then
    vim.opt.number = false
    vim.opt.relativenumber = false
    vim.opt.signcolumn = "no"
    vim.opt.list = false
    vim.wo.list = false -- window-local setting
    vim.cmd("IBLDisable")
    vim.cmd("TSContextDisable")
    vim.diagnostic.disable()
    -- Disable mini.indentscope
    vim.b.miniindentscope_disable = true
    if ns_id then
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    end
    -- Clear all virtual text (any remaining indent guides, decorators, etc.)
    for _, ns in pairs(vim.api.nvim_get_namespaces()) do
      vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    end
    -- Disable gitsigns
    if gs_ok then
      gitsigns.detach()
    end

    vim.cmd("silent! redraw")
    clean_view_enabled = true
  else
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.signcolumn = "yes"
    vim.opt.list = true
    vim.wo.list = true
    vim.opt.listchars = saved_listchars
    vim.cmd("IBLEnable")
    vim.cmd("TSContextEnable")
    vim.diagnostic.enable()
    -- Re-enable mini.indentscope
    vim.b.miniindentscope_disable = false
    if scope_ok and type(indentscope.enable) == "function" then
      indentscope.enable()
    end
    -- Re-enable gitsigns
    if gs_ok and type(gitsigns.attach) == "function" then
      gitsigns.attach()
    end

    clean_view_enabled = false
  end
end
-- Add a keybind for it
vim.api.nvim_set_keymap('n', '<leader>cv', '<cmd>lua CleanViewToggle()<enter>', { noremap = true, silent = true, desc = "[c]lean [v]iew [t]oggle Toggle" })

