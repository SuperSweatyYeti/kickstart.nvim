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

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'ps1',
        callback = function(args)
          vim.keymap.set('n', '<leader>dpd', function()
            require('powershell').toggle_debug_term()
          end, { buffer = args.buf, desc = 'PowerShell: Toggle Debug Terminal' })

          local ps_layout_initialized = false

          -- Override continue for ps1 to setup layout on first run
          vim.keymap.set('n', '<leader>dc', function()
            if not ps_layout_initialized then
              dapui.setup { layouts = ps_layout }
              ps_layout_initialized = true
            end
            dap.continue()
          end, { buffer = true, desc = 'Continue (PS)' })

          -- Reset the flag when the session ends
          local function reset_layout(session)
            if session.config and session.config.type == 'ps1' then
              ps_layout_initialized = false
              dapui.setup()
            end
          end

          dap.listeners.after.event_terminated.powershell_layout = reset_layout
          dap.listeners.after.event_exited.powershell_layout = reset_layout
          dap.listeners.after.disconnect.powershell_layout = reset_layout
        end,
      })

      -- After DAP is fully initialized, open the PS debug terminal
      dap.listeners.after.event_stopped.powershell_debug_term = function(session)
        if session.config and session.config.type == 'ps1' then
          -- Only open once — check if it's already visible
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
              -- Less than half split  1/8
              vim.api.nvim_win_set_height(term_win, math.floor(vim.o.lines / 8))
              vim.api.nvim_set_current_win(prev_win)
            end
          end
        end
      end
    end,
  },
}
