return {
  {
    'mfussenegger/nvim-dap',
    enabled = true,
    -- lazy = true,
    -- Copied from LazyVim/lua/lazyvim/plugins/extras/dap/core.lua and
    -- modified.
    dependencies = {
      {
        'rcarriga/nvim-dap-ui',
        keys = {
          {
            '<leader>du',
            function()
              require('dapui').toggle {}
            end,
            desc = 'Dap UI',
          },
        },
      },

      'nvim-neotest/nvim-nio',
      -- Specific languages here
      {
        'mfussenegger/nvim-dap-python',
        config = function(_, opts)
          local python = vim.fn.expand '~/.local/share/nvim/mason/packages/debugpy/venv/bin/python'
          require('dap-python').setup(python)
          -- table.insert(require('dap').configurations.python, {
          --   type = 'python',
          --   request = 'launch',
          --   name = 'Module',
          --   console = 'integratedTerminal',
          --   module = 'src', -- edit this to be your app's main module
          --   cwd = '${workspaceFolder}',
          -- })
        end,
      },
      {
        -- Not working in linux
        'Willem-J-an/nvim-dap-powershell',
        enabled = false,
        dependencies = {
          'nvim-lua/plenary.nvim',
          'mfussenegger/nvim-dap',
          'rcarriga/nvim-dap-ui',
          {
            'm00qek/baleia.nvim',
            lazy = true,
            tag = 'v1.4.0',
          },
        },
        config = function()
          require('dap-powershell').setup()
        end,
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
              if #variable.value > 25 then
                return '= ' .. variable.value:sub(1, 25) .. '...'
              end
              return '= ' .. variable.value
            end,
            -- position of virtual text, see `:h nvim_buf_set_extmark()`, default tries to inline the virtual text. Use 'eol' to set to end of line
            -- virt_text_pos = vim.fn.has 'nvim-0.10' == 1 and 'inline' or 'eol',

            virt_text_pos = vim.fn.has 'nvim-0.10' == 1 and 'eol',
            highlight_changed_variables = false,
            all_frames = false,
          }
        end,
      },
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      require('dapui').setup()

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
      vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStoppedColor', linehl = 'DapStoppedLineBgColor', numhl = 'DapBreakpointColor' })

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
        ':lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))<enter>',
        desc = 'Set [d]ebug [b]reakpoint [c]onditional',
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
  },
}
