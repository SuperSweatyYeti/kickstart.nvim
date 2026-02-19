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
      -- Language-specific debug configs in debugging-*.lua files
      {
        'theHamsta/nvim-dap-virtual-text',
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
      dap.listeners.before.disconnect['dapui_config'] = function()
        dapui.close()
      end
      vim.cmd 'hi DapBreakpointColor guifg=#fa4848'
      vim.cmd 'hi DapBreakpointConditionColor guifg=#fa4848'
      vim.cmd 'hi DapStoppedColor guifg=#f7ce00'
      vim.cmd 'hi DapStoppedLineBgColor guibg=#57551e'
      vim.cmd 'hi DapStoppedOnBreakpointColor guifg=#ec5d00'
      vim.fn.sign_define('DapBreakpointCondition', { text = '', texthl = 'DapBreakpointConditionColor' })
      vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DapBreakpointColor', linehl = '', numhl = '' })
      vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStoppedColor', linehl = 'DapStoppedLineBgColor', numhl = 'DapBreakpointColor' })

      -- Change DapStopped sign when stopped on a breakpoint
      dap.listeners.after.event_stopped['custom_stopped_on_bp'] = function(_, body)
        if body and body.reason == 'breakpoint' then
          vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStoppedOnBreakpointColor', linehl = 'DapStoppedLineBgColor', numhl = 'DapBreakpointColor' })
        else
          vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStoppedColor', linehl = 'DapStoppedLineBgColor', numhl = 'DapBreakpointColor' })
        end
      end

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
