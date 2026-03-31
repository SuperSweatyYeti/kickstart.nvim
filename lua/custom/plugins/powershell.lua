return {
  {
    'TheLeoP/powershell.nvim',
    enabled = true,
    dependencies = {
      'mfussenegger/nvim-dap',
    },
    ---@type powershell.user_config
    opts = {
      bundle_path = vim.fn.stdpath 'data' .. '/mason/packages/powershell-editor-services',
    },
    config = function(_, opts)
      require('powershell').setup(opts)

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'ps1',
        callback = function(args)
          -- vim.keymap.set({ 'n', 'x' }, '<leader>dpe', function() require('powershell').eval() end, { buffer = args.buf, desc = 'PowerShell: Eval' })
          -- vim.keymap.set('n', '<leader>dpt', function() require('powershell').toggle_term() end, { buffer = args.buf, desc = 'PowerShell: Toggle Terminal' })
          vim.keymap.set('n', '<leader>dpd', function() require('powershell').toggle_debug_term() end, { buffer = args.buf, desc = 'PowerShell: Toggle Debug Terminal' })
        end,
      })
    end,
  },
}
