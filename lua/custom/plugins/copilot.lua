return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        -- Disable the default keymap to accept suggestions
        vim.keymap.set('i', '<Tab>', '<Tab>'),
        panel = {
          enabled = false,
          auto_refresh = false,
          keymap = {
            jump_prev = '[[',
            jump_next = ']]',
            accept = '<CR>',
            refresh = 'gr',
            open = '<M-CR>',
          },
          layout = {
            position = 'bottom', -- | top | left | right | horizontal | vertical
            ratio = 0.4,
          },
        },
        suggestion = {
          enabled = false, -- Disabled because we are using `copilot-cmp` for completion
          auto_trigger = true,
          hide_during_completion = true,
          debounce = 75,
          keymap = {
            accept = '<C-y>',
            accept_word = false,
            accept_line = false,
            next = '<C-n>', -- Next suggestion
            prev = '<C-p>', -- Previous suggestion
            dismiss = '<C-]>',
          },
        },
        filetypes = {
          yaml = false,
          markdown = false,
          help = false,
          gitcommit = false,
          gitrebase = false,
          hgcommit = false,
          svn = false,
          cvs = false,
          ['.'] = false,
        },
        logger = {
          file = vim.fn.stdpath 'log' .. '/copilot-lua.log',
          file_log_level = vim.log.levels.OFF,
          print_log_level = vim.log.levels.WARN,
          trace_lsp = 'off', -- "off" | "messages" | "verbose"
          trace_lsp_progress = false,
          log_lsp_messages = false,
        },
        copilot_node_command = 'node', -- Node.js version must be > 20
        workspace_folders = {},
        copilot_model = '', -- Current LSP default is gpt-35-turbo, supports gpt-4o-copilot
        root_dir = function()
          return vim.fs.dirname(vim.fs.find('.git', { upward = true })[1])
        end,

        -- should_attach = function(_, _)
        --   if not vim.bo.buflisted then
        --     logger.debug "not attaching, buffer is not 'buflisted'"
        --     return false
        --   end
        --
        --   if vim.bo.buftype ~= '' then
        --     logger.debug("not attaching, buffer 'buftype' is " .. vim.bo.buftype)
        --     return false
        --   end
        --
        --   return true
        -- end,
        server = {
          type = 'nodejs', -- "nodejs" | "binary"
          custom_server_filepath = nil,
        },
        server_opts_overrides = {},
      }
    end,
  },
  -- Plugin to have copilot sugestions play nice with nvim-cmp
  {
    'zbirenbaum/copilot-cmp',
    config = function()
      require('copilot_cmp').setup()
    end,
  },
  -- Additon to lualine to show copilot status
  {
    'AndreM222/copilot-lualine',
    -- Edit lualine setup to include copilot in the statusline
    config = function()
      -- Ensure lualine is loaded before setting up
      local statusline = require('lualine')
      if not statusline then
        return
      end
      -- Setup lualine with copilot
      statusline.setup {
        sections = {
          lualine_x = { 'copilot', 'encoding', 'fileformat', 'filetype' },
        },
      }
    end,
  },
}
