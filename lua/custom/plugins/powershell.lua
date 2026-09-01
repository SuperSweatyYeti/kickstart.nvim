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
      bundle_path = vim.fn.stdpath('data')
        .. '/mason/packages/powershell-editor-services',
    },

    config = function(_, opts)
      ----------------------------------------------------------------------
      -- PowerShell Editor Services
      --
      -- Keep LSP configuration separate from powershell.nvim.
      --
      -- IMPORTANT:
      -- powershell.nvim provides the PowerShell integration/debugging.
      -- vim.lsp.config() configures the actual powershell_es LSP client.
      ----------------------------------------------------------------------

      vim.lsp.config('powershell_es', {
        bundle_path = opts.bundle_path,

        settings = {
          powershell = {
            codeFormatting = {
              -- Explicitly use the custom formatter settings.
              preset = 'Custom',

              -- Braces
              openBraceOnSameLine = true,
              newLineAfterOpenBrace = true,
              newLineAfterCloseBrace = false,

              -- Indentation
              pipelineIndentationStyle =
                'IncreaseIndentationForFirstPipeline',

              -- Whitespace
              whitespaceBeforeOpenBrace = true,
              whitespaceBeforeOpenParen = true,
              whitespaceAroundOperator = true,
              whitespaceAfterSeparator = true,
              whitespaceBetweenParameters = false,
              whitespaceInsideBrace = true,

              addWhitespaceAroundPipe = true,
              trimWhitespaceAroundPipe = false,

              -- Miscellaneous
              ignoreOneLineBlock = true,
              alignPropertyValuePairs = true,

              useConstantStrings = false,
              useCorrectCasing = true,

              autoCorrectAliases = true,
            },
          },
        },
      })

      ----------------------------------------------------------------------
      -- PowerShell executable selection
      ----------------------------------------------------------------------

      local powershell_versions = {
        ['5.1'] = 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
        ['7+'] = 'pwsh',
      }

      local current_version = '7+'

      local function setup_powershell(version)
        require('powershell').setup({
          executable = powershell_versions[version],
          bundle_path = opts.bundle_path,
        })
      end

      local function select_powershell_version(version)
        if not powershell_versions[version] then
          print('Invalid PowerShell version: ' .. version)
          return
        end

        current_version = version

        setup_powershell(version)

        print('Switched to PowerShell ' .. version)
      end

      ----------------------------------------------------------------------
      -- Default PowerShell setup
      ----------------------------------------------------------------------

      setup_powershell(current_version)

      ----------------------------------------------------------------------
      -- Telescope: choose PowerShell version
      ----------------------------------------------------------------------

      local function telescope_choose_powershell()
        local choices = {}

        if vim.fn.executable(powershell_versions['5.1']) == 1 then
          table.insert(choices, {
            name = 'PowerShell 5.1',
            version = '5.1',
          })
        end

        if vim.fn.executable(powershell_versions['7+']) == 1 then
          table.insert(choices, {
            name = 'PowerShell 7+',
            version = '7+',
          })
        end

        require('telescope.pickers')
          .new({}, {
            prompt_title = 'Choose PowerShell Version',

            finder = require('telescope.finders').new_table({
              results = choices,

              entry_maker = function(entry)
                local display_name = entry.name

                if entry.version == current_version then
                  display_name = ' ' .. display_name
                end

                return {
                  value = entry.version,
                  display = display_name,
                  ordinal = entry.name,
                }
              end,
            }),

            sorter =
              require('telescope.config').values.generic_sorter({}),

            layout_config = {
              prompt_position = 'top',
              height = 10,
              width = 50,
            },

            attach_mappings = function(_, map)
              map('i', '<CR>', function(prompt_bufnr)
                local selection =
                  require('telescope.actions.state')
                    .get_selected_entry()

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

      vim.keymap.set(
        'n',
        '<leader>ps',
        telescope_choose_powershell,
        {
          desc = 'Choose PowerShell Version',
        }
      )

      ----------------------------------------------------------------------
      -- DAP
      ----------------------------------------------------------------------

      local dap = require('dap')
      local dapui = require('dapui')

      ----------------------------------------------------------------------
      -- PowerShell DAP layout
      ----------------------------------------------------------------------

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

      ----------------------------------------------------------------------
      -- PowerShell buffer mappings
      ----------------------------------------------------------------------

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'ps1',

        callback = function(args)
          local bufnr = args.buf

          vim.keymap.set('n', '<leader>dpd', function()
            require('powershell').toggle_debug_term()
          end, {
            buffer = bufnr,
            desc = 'PowerShell: Toggle Debug Terminal',
          })

          vim.keymap.set('n', '<leader>dc', function()
            if dap.session() == nil then
              dapui.setup({
                layouts = ps_layout,
              })
            end

            dap.continue()
          end, {
            buffer = bufnr,
            desc = 'Continue (PS)',
          })
        end,
      })

      ----------------------------------------------------------------------
      -- Automatically open PowerShell debug terminal
      ----------------------------------------------------------------------

      dap.listeners.after.event_stopped.powershell_debug_term =
        function(session)
          if not session.config
            or session.config.type ~= 'ps1'
          then
            return
          end

          local already_open = false

          for _, win in ipairs(
            vim.api.nvim_tabpage_list_wins(0)
          ) do
            local buf = vim.api.nvim_win_get_buf(win)

            if vim.bo[buf].buftype == 'terminal' then
              local name =
                vim.api.nvim_buf_get_name(buf):lower()

              if name:find('pwsh')
                or name:find('powershell')
              then
                already_open = true
                break
              end
            end
          end

          if already_open then
            return
          end

          local previous_window =
            vim.api.nvim_get_current_win()

          require('powershell').toggle_debug_term()

          local terminal_window =
            vim.api.nvim_get_current_win()

          if terminal_window ~= previous_window then
            vim.api.nvim_win_set_height(
              terminal_window,
              math.floor(vim.o.lines / 8)
            )

            vim.api.nvim_set_current_win(
              previous_window
            )
          end
        end

      ----------------------------------------------------------------------
      -- Restore default DAP UI layout
      ----------------------------------------------------------------------

      local function restore_layout(session)
        if session.config
          and session.config.type == 'ps1'
        then
          dapui.setup()
        end
      end

      dap.listeners.after.event_terminated.powershell_layout =
        restore_layout

      dap.listeners.after.event_exited.powershell_layout =
        restore_layout

      dap.listeners.after.disconnect.powershell_layout =
        restore_layout
    end,
  },
}

