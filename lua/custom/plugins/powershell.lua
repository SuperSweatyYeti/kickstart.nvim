return {
  {
    'TheLeoP/powershell.nvim',
    enabled = true,
    dependencies = {
      'mfussenegger/nvim-dap',
      'rcarriga/nvim-dap-ui',
    },
    ---@type powershell.user_config
    opts = {
      bundle_path = vim.fn.stdpath 'data' .. '/mason/packages/powershell-editor-services',
    },
    config = function(_, opts)
      require('powershell').setup(opts)

      local dap = require 'dap'
      local dapui = require 'dapui'

      -- PowerShell layout: no console, repl full-width bottom
      local ps_layout = {
        {
          elements = {
            { id = 'scopes', size = 0.25 },
            { id = 'breakpoints', size = 0.25 },
            { id = 'stacks', size = 0.25 },
            { id = 'watches', size = 0.25 },
          },
          position = 'left',
          size = 40,
        },
        {
          elements = {
            { id = 'repl', size = 1.0 },
          },
          position = 'bottom',
          size = 6,
        },
      }

      -- Track cursor position to prevent DAP from moving it
      local saved_cursor = nil
      local should_restore_cursor = false

      local function save_cursor()
        saved_cursor = {
          win = vim.api.nvim_get_current_win(),
          buf = vim.api.nvim_get_current_buf(),
          pos = vim.api.nvim_win_get_cursor(0),
        }
        should_restore_cursor = true
      end

      local function restore_cursor()
        if should_restore_cursor and saved_cursor then
          -- Only restore if the window and buffer are still valid
          if vim.api.nvim_win_is_valid(saved_cursor.win)
            and vim.api.nvim_buf_is_valid(saved_cursor.buf)
            and vim.api.nvim_win_get_buf(saved_cursor.win) == saved_cursor.buf
          then
            vim.api.nvim_set_current_win(saved_cursor.win)
            vim.api.nvim_win_set_cursor(saved_cursor.win, saved_cursor.pos)
          end
          should_restore_cursor = false
        end
      end

      -- Restore cursor after DAP jumps to the stopped location
      dap.listeners.after.event_stopped.powershell_cursor = function(session)
        if session.config and session.config.type == 'ps1' then
          -- Defer to let DAP finish its jump first
          vim.defer_fn(restore_cursor, 50)
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'ps1',
        callback = function(args)
          vim.keymap.set('n', '<leader>dpd', function()
            require('powershell').toggle_debug_term()
          end, { buffer = args.buf, desc = 'PowerShell: Toggle Debug Terminal' })

          vim.keymap.set('n', '<leader>dc', function()
            if dap.session() == nil then
              dapui.setup { layouts = ps_layout }
            else
              save_cursor()
            end
            dap.continue()
          end, { buffer = true, desc = 'Continue (PS)' })

          vim.keymap.set('n', '<leader>dso', function()
            save_cursor()
            dap.step_over()
          end, { buffer = true, desc = 'Step Over (PS, stay)' })

          vim.keymap.set('n', '<leader>dsi', function()
            save_cursor()
            dap.step_into()
          end, { buffer = true, desc = 'Step Into (PS, stay)' })

          vim.keymap.set('n', '<leader>dsO', function()
            save_cursor()
            dap.step_out()
          end, { buffer = true, desc = 'Step Out (PS, stay)' })
        end,
      })

      -- After DAP is fully initialized, open the PS debug terminal
      dap.listeners.after.event_stopped.powershell_debug_term = function(session)
        if session.config and session.config.type == 'ps1' then
          local already_open = false
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].buftype == 'terminal' then
              local name = vim.api.nvim_buf_get_name(buf)
              if name:lower():find('pwsh') or name:lower():find('powershell') then
                already_open = true
                break
              end
            end
          end

          if not already_open then
            local prev_win = vim.api.nvim_get_current_win()
            require('powershell').toggle_debug_term()
            local term_win = vim.api.nvim_get_current_win()
            if term_win ~= prev_win then
              vim.api.nvim_win_set_height(term_win, math.floor(vim.o.lines / 8))
              vim.api.nvim_set_current_win(prev_win)
            end
          end
        end
      end

      -- Restore default layout when PS session ends
      local function restore_layout(session)
        if session.config and session.config.type == 'ps1' then
          saved_cursor = nil
          should_restore_cursor = false
          dapui.setup()
        end
      end

      dap.listeners.after.event_terminated.powershell_layout = restore_layout
      dap.listeners.after.event_exited.powershell_layout = restore_layout
      dap.listeners.after.disconnect.powershell_layout = restore_layout
    end,
  },
}
