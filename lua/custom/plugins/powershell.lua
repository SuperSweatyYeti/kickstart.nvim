
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
      -- Function to dynamically select PowerShell version
      local powershell_versions = {
        ['5.1'] = 'C:\\\\Windows\\\\System32\\\\WindowsPowerShell\\\\v1.0\\\\powershell.exe',
        ['7+'] = 'pwsh.exe',
      }

      local current_version = '7+' -- Default to PowerShell 7+

      local function select_powershell_version(version)
        if powershell_versions[version] then
          current_version = version
          require('powershell').setup {
            executable = powershell_versions[version],
            bundle_path = opts.bundle_path,
          }
          print('Switched to PowerShell ' .. version)
        else
          print('Invalid PowerShell version: ' .. version)
        end
      end

      -- Default setup with PowerShell 7+
      require('powershell').setup {
        executable = powershell_versions[current_version],
        bundle_path = opts.bundle_path,
      }

      -- Telescope integration to choose PowerShell version
      local function telescope_choose_powershell()
        local choices = {}
        if vim.fn.executable(powershell_versions['5.1']) == 1 then
          table.insert(choices, { name = 'PowerShell 5.1', version = '5.1' })
        end
        if vim.fn.executable(powershell_versions['7+']) == 1 then
          table.insert(choices, { name = 'PowerShell 7+', version = '7+' })
        end

        require('telescope.pickers')
          .new({}, {
            prompt_title = 'Choose PowerShell Version',
            finder = require('telescope.finders').new_table {
              results = choices,
              entry_maker = function(entry)
                local display_name = entry.name
                if entry.version == current_version then
                  display_name = '• ' .. display_name -- Add bullet for the active version
                end
                return {
                  value = entry.version,
                  display = display_name,
                  ordinal = entry.name,
                }
              end,
            },
            sorter = require('telescope.config').values.generic_sorter {},
            layout_config = {
              prompt_position = 'top', -- Move input field to the top
              height = 10,             -- Adjust the height of the picker
              width = 50,              -- Adjust the width of the picker
            },
            attach_mappings = function(_, map)
              map('i', '<CR>', function(prompt_bufnr)
                local selection = require('telescope.actions.state').get_selected_entry()
                require('telescope.actions').close(prompt_bufnr)
                if selection then
                  select_powershell_version(selection.value)
                end
              end)
              return true
            end,
          })
          :find()
      end

      -- Keymap to invoke the Telescope picker
      vim.keymap.set('n', '<leader>ps', telescope_choose_powershell, { desc = 'Choose PowerShell Version' })

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

          -- Override continue for ps1 to setup layout before first launch
          vim.keymap.set('n', '<leader>dc', function()
            if dap.session() == nil then
              dapui.setup { layouts = ps_layout }
            end
            dap.continue()
          end, { buffer = true, desc = 'Continue (PS)' })
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
              if name:lower():find 'pwsh' or name:lower():find 'powershell' then
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

      -- Restore default layout when PS session ends
      local function restore_layout(session)
        if session.config and session.config.type == 'ps1' then
          dapui.setup()
        end
      end

      dap.listeners.after.event_terminated.powershell_layout = restore_layout
      dap.listeners.after.event_exited.powershell_layout = restore_layout
      dap.listeners.after.disconnect.powershell_layout = restore_layout
    end,
  },
}
