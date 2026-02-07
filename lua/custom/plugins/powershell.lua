return {
  {
    -- NOTE: This plugin includes DAP config by default.
    'TheLeoP/powershell.nvim',
    enabled = false,
    ---@type powershell.user_config
    opts = {
      bundle_path = vim.fn.stdpath 'data' .. '/mason/packages/powershell-editor-services',
    },
  },
}
