return {

  -- 'jay-babu/mason-nvim-dap.nvim',
  -- 'mfussenegger/nvim-dap',
  -- dependencies = {
  --   'mfussenegger/nvim-dap-python',
  --   'rcarriga/nvim-dap-ui',
  -- },
  -- config = function()
  --   require('dapui').setup()
  --   require('dap-python').setup()
  --
  --   local dap, dapui = require 'dap', require 'dapui'
  --
  --   dap.listeners.before.attach.dapui_config = function()
  --     dapui.open()
  --   end
  --   dap.listeners.before.launch.dapui_config = function()
  --     dapui.open()
  --   end
  --   dap.listeners.before.event_terminated.dapui_config = function()
  --     dapui.close()
  --   end
  --   dap.listeners.before.event_exited.dapui_config = function()
  --     dapui.close()
  --   end
  --
  --   vim.keymap.set('n', '<Leader>dt', ':DapToggleBreakpoint<CR>')
  --   vim.keymap.set('n', '<Leader>dc', ':DapContinue<CR>')
  --   vim.keymap.set('n', '<Leader>dx', ':DapTerminate<CR>')
  --   vim.keymap.set('n', '<Leader>do', ':DapStepOver<CR>')
  -- end,

  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
    'mfussenegger/nvim-dap-python',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_setup = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {

        function(config)
          -- all sources with no handler get passed here

          -- Keep original functionality
          require('mason-nvim-dap').default_setup(config)
        end,
        python = function(config)
          config.adapters = {
            type = 'executable',
            command = '/usr/bin/python3',
            args = {
              '-m',
              'debugpy.adapter',
            },
          }
          require('mason-nvim-dap').default_setup(config) -- don't forget this!
        end,
      },

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'debugpy',
      },
    }

    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<Leader>dc', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<Leader>di', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<Leader>do', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<Leader>dO', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<Leader>dB', dap.step_back, { desc = 'Debug: Step Back' })
    vim.keymap.set('n', '<Leader>dT', dap.terminate, { desc = 'Debug: Terminate' })
    vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = '🔙',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Install golang specific config
    require('dap-go').setup()
  end,
}
