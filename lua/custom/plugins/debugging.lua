return {
  -- keep-sorted start block=yes

  {
    'mfussenegger/nvim-dap',
    enabled = true,
    -- lazy = true,
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
      vim.cmd 'hi DapBreakpointColor guifg=#fa4848'
      vim.cmd 'hi DapBreakpointConditionColor guifg=#fa4848'
      vim.cmd 'hi DapStoppedColor guifg=#faa448' -- yello\w background for stopped line
      vim.cmd 'hi DapStoppedLineBgColor guibg=#57551e'
      vim.fn.sign_define('DapBreakpointCondition', { text = '', texthl = 'DapBreakpointConditionColor' })
      vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DapBreakpointColor', linehl = '', numhl = '' })
      vim.fn.sign_define('DapStopped', { texthl = 'DapStoppedColor', linehl = 'DapStoppedLineBgColor', numhl = 'DapBreakpointColor' })

      -- reload current color scheme to pick up colors override if it was set up in a lazy plugin definition fashion
      -- vim.cmd.colorscheme(vim.g.colors_name)
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
        '<leader>dbc',
        ':lua require("dap").toggle_breakpoint(" i == 5 ")',
        desc = 'Toggle Conditional Breakpoint',
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
                  -- 'delve',
                  -- 'python',
                },
              },
              -- DAP servers: Mason will be invoked to install these if necessary.
              ensure_installed = {
                'bash',
                'codelldb',
                'php',
                'debugpy',
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
            -- config = true,
            dependencies = {
              'mfussenegger/nvim-dap',
            },
            config = function()
              local virtualtext = require 'nvim-dap-virtual-text'
              virtualtext.setup {
                display_callback = function(variable)
                  if #variable.value > 15 then
                    return ' ' .. variable.value:sub(1, 15) .. '...'
                  end
                  return ' ' .. variable.value
                end,
              }
            end,
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
            -- lazy = true,
            config = function(_, opts)
              local python = vim.fn.expand '~/.local/share/nvim/mason/packages/debugpy/venv/bin/python'
              require('dap-python').setup(python)
              table.insert(require('dap').configurations.python, {
                type = 'python',
                request = 'launch',
                name = 'Module',
                console = 'integratedTerminal',
                module = 'src', -- edit this to be your app's main module
                cwd = '${workspaceFolder}',
              })
            end,
            -- Consider the mappings at
            -- https://github.com/mfussenegger/nvim-dap-python?tab=readme-ov-file#mappings
            dependencies = {
              'mfussenegger/nvim-dap',
              'rcarriga/nvim-dap-ui',
            },
          },
          -- keep-sorted end
        },
      },
    },
  },
  -- keep-sorted end
}




