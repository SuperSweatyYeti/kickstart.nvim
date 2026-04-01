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

      -- Change cursor behavior with dap and dapui
      -- Stepping does not grab the cursor from other buffers/panes and make the cursor move to stopped line
      -- UNLESS we are already in the actual source code buffer
      --
      -- Write directly into the existing fallback table, bypassing the
      -- __newindex metamethod which would wipe it out.
      local fallback = rawget(dap.defaults, 'fallback')
      fallback.switchbuf = function(bufnr, line, column)
        local cur_win = vim.api.nvim_get_current_win()
        local cur_buf = vim.api.nvim_get_current_buf()

        if cur_buf == bufnr then
          local saved_scrolloff = vim.wo[cur_win].scrolloff
          vim.wo[cur_win].scrolloff = math.floor(vim.api.nvim_win_get_height(cur_win) / 4)
          pcall(vim.api.nvim_win_set_cursor, cur_win, { line, (column or 1) - 1 })
          vim.wo[cur_win].scrolloff = saved_scrolloff
        else
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_get_buf(win) == bufnr then
              local saved_scrolloff = vim.wo[win].scrolloff
              vim.wo[win].scrolloff = math.floor(vim.api.nvim_win_get_height(win) / 4)
              pcall(vim.api.nvim_win_set_cursor, win, { line, 0 })
              vim.wo[win].scrolloff = saved_scrolloff
              break
            end
          end
        end
      end

      -- Clear Virutal Text on close/stop
      local dap = require 'dap'
      dap.listeners.before.event_terminated['clear-virtual-text'] = function()
        require('nvim-dap-virtual-text.virtual_text').clear_virtual_text()
        require('nvim-dap-virtual-text.virtual_text').clear_last_frames()
      end
      dap.listeners.before.disconnect['clear-virtual-text'] = function()
        require('nvim-dap-virtual-text.virtual_text').clear_virtual_text()
        require('nvim-dap-virtual-text.virtual_text').clear_last_frames()
      end

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
          vim.fn.sign_define(
            'DapStopped',
            { text = '', texthl = 'DapStoppedOnBreakpointColor', linehl = 'DapStoppedLineBgColor', numhl = 'DapBreakpointColor' }
          )
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
      -- Go to the stopped line
      {
        '<leader>dg',
        function()
          local session = require('dap').session()
          if not session then
            vim.notify('No active DAP session', vim.log.levels.WARN)
            return
          end
          local frame = session.current_frame
          if not frame or not frame.source or not frame.source.path then
            vim.notify('No current frame', vim.log.levels.WARN)
            return
          end
          vim.cmd('edit ' .. vim.fn.fnameescape(frame.source.path))
          vim.api.nvim_win_set_cursor(0, { frame.line, (frame.column or 1) - 1 })
        end,
        desc = 'Go to Stopped Line',
      },
    },
  },
}
