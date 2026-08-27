local enabled = true

if not enabled then
  return {}
end

return {
  {
    'jay-babu/mason-nvim-dap.nvim',
    dependencies = {
      'mfussenegger/nvim-dap',
      'williamboman/mason.nvim',
    },
    config = function()
      local dap = require 'dap'

      require('mason-nvim-dap').setup {
        ensure_installed = {
          'codelldb',
        },
        automatic_installation = true,
      }

      if is_os_linux() then
        dap.adapters.codelldb = {
          type = 'executable',
          command = vim.fn.expand(
            '~/.local/share/nvim/mason/packages/codelldb/extension/adapter/codelldb'
          ),
        }
      elseif is_os_windows() then
        dap.adapters.codelldb = {
          type = 'executable',
          command = vim.fn.expand(
            '~/AppData/Local/nvim-data/mason/packages/codelldb/extension/adapter/codelldb.exe'
          ),
        }
      end

      dap.configurations.cpp = {
        {
          name = 'Launch C++',
          type = 'codelldb',
          request = 'launch',

          program = function()
            return vim.fn.input(
              'Path to executable: ',
              vim.fn.getcwd() .. '/',
              'file'
            )
          end,

          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        },
      }
    end,
  },
}

