return {
  -- keep-sorted start block=yes

  {
    'mfussenegger/nvim-dap',
    enabled = true,
    lazy = true,
    -- Copied from LazyVim/lua/lazyvim/plugins/extras/dap/core.lua and
    -- modified.
    config = function()
      local dap, dapui = require 'dap', require 'dapui'
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end,

    keys = {
      {
        '<leader>db',
        function()
          require('dap').toggle_breakpoint()
        end,
        desc = 'Toggle Breakpoint',
      },

      {
        '<leader>dc',
        function()
          require('dap').continue()
        end,
        desc = 'Continue',
      },

      {
        '<leader>do',
        function()
          require('dap').step_over()
        end,
        desc = 'Step Over',
      },
      {
        '<leader>dO',
        function()
          require('dap').step_out()
        end,
        desc = 'Step Out',
      },

      {
        '<leader>di',
        function()
          require('dap').step_into()
        end,
        desc = 'Step Into',
      },
      {
        '<leader>dB',
        function()
          require('dap').step_back()
        end,
        desc = 'Step Back',
      },

      {
        '<leader>dC',
        function()
          require('dap').run_to_cursor()
        end,
        desc = 'Run to Cursor',
      },

      {
        '<leader>dT',
        function()
          require('dap').terminate()
        end,
        desc = 'Terminate',
      },
    },
    dependencies = {
      {
        'rcarriga/nvim-dap-ui',
        config = true,
        keys = {
          {
            '<leader>du',
            function()
              require('dapui').toggle {}
            end,
            desc = 'Dap UI',
          },
        },
        dependencies = {
          -- keep-sorted start block=yes
          {
            'jay-babu/mason-nvim-dap.nvim',
            ---@type MasonNvimDapSettings
            opts = {
              -- This line is essential to making automatic installation work
              -- :exploding-brain
              handlers = {},
              automatic_installation = {
                -- These will be configured by separate plugins.
                exclude = {
                  'delve',
                  'python',
                },
              },
              -- DAP servers: Mason will be invoked to install these if necessary.
              ensure_installed = {
                'bash',
                'codelldb',
                'php',
                'python',
              },
            },
            dependencies = {
              'mfussenegger/nvim-dap',
              'williamboman/mason.nvim',
            },
          },
          {
            'nvim-neotest/nvim-nio',
          },
          {
            'theHamsta/nvim-dap-virtual-text',
            config = true,
            dependencies = {
              'mfussenegger/nvim-dap',
            },
          },
          -- Languages Section
          {
            'leoluz/nvim-dap-go',
            config = true,
            dependencies = {
              'mfussenegger/nvim-dap',
            },
            keys = {
              {
                '<leader>dt',
                function()
                  require('dap-go').debug_test()
                end,
                desc = 'Debug test',
              },
            },
          },
          {
            'mfussenegger/nvim-dap-python',
            lazy = true,
            config = function()
              local python = vim.fn.expand '~/.local/share/nvim/mason/packages/debugpy/venv/bin/python'
              require('dap-python').setup(python)
            end,
            -- Consider the mappings at
            -- https://github.com/mfussenegger/nvim-dap-python?tab=readme-ov-file#mappings
            dependencies = {
              'mfussenegger/nvim-dap',
            },
          },
          -- keep-sorted end
        },
      },
    },
  },
  -- keep-sorted end
}

--[[
-- NOTE: Previous config here
return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Python Debug adapter
    -- NOTE need to install debugpy with `pip install debugpy`
    'mfussenegger/nvim-dap-python',
    -- NOTE Needed for python 
    'nvim-neotest/nvim-nio',
    -- Pretty UI
    'rcarriga/nvim-dap-ui',
    -- Mason plugin to install debug adapters
    'jay-babu/mason-nvim-dap.nvim',
  },
  config = function()
    -- Variable for python venv mason path user's Home folder
    local userFolder =  os.getenv( "HOME" )

    local dap = require 'dap'
    local dapui = require 'dapui'
    require('dap-python').setup()
    require('dapui').setup()

    -- Open/Close Dap UI automatically when debugging
    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    -- Debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })
    vim.keymap.set('n', '<Leader>dc', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F5>', dapui.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<Leader>di', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F11>', dapui.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<Leader>do', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F10>', dapui.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<Leader>dO', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<Leader>dB', dap.step_back, { desc = 'Debug: Step Back' })
    vim.keymap.set('n', '<Leader>dT', dap.terminate, { desc = 'Debug: Terminate' })
    vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>dU', dapui.toggle, { desc = 'Debug: Toggle Dap UI' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })
    vim.keymap.set('n', '<leader>drb', dap.clear_breakpoints, { desc = 'Debug: [r]emove all [b]reakpoints' })

    -- mason-nvim setup
    require('mason-nvim-dap').setup {
      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'debugpy',
      },
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
        -- Python Setup with the correct path of the venv where debugpy
        -- gets installed by mason
        python = function(config)
          config.adapters = {
            type = 'executable',
            -- command  '/usr/bin/python',
            -- This should be the default config honestly?
            command = (userFolder .. '/.local/share/nvim/mason/packages/debugpy/venv/bin/python'),
            args = {
              '-m',
              'debugpy.adapter',
            },
          }
          require('mason-nvim-dap').default_setup(config) -- don't forget this!
        end,
      },

    }
  end,

}
 --]]
