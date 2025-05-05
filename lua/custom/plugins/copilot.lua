-- Copilot Model Variable
local copilotModel = 'claude-3.7-sonnet-thought'
return {
  {
    -- Requires nodejs to be installed
    'zbirenbaum/copilot.lua',
    enabled = true,
    cmd = 'Copilot',
    vim.keymap.set('n', '<leader>cp', '<cmd>Copilot<cr>', { desc = 'Start Copilot' }),
    -- event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        -- Disable the default keymap to accept suggestions
        vim.keymap.set('i', '<Tab>', '<Tab>'),
        vim.keymap.set('n', '<leader>cp', '<cmd>Copilot<cr>', { desc = 'Start Copilot' }),
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
          enabled = true, -- Disabled because we are using `copilot-cmp` for completion
          auto_trigger = false,
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
        -- Set Claude 3.7 as the default model
        copilot_model = copilotModel, -- Current LSP default is gpt-35-turbo, supports gpt-4o-copilot
        root_dir = function()
          return vim.fs.dirname(vim.fs.find('.git', { upward = true })[1])
        end,
        -- Disabled the following lines to prevent copilot issue with neotree and telescope buffers
        -- which was returning nil values sometimes
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
    dependencies = {
      -- Plugin to have copilot sugestions play nice with nvim-cmp
      {
        'zbirenbaum/copilot-cmp',
        -- enable = true,
        config = function()
          require('copilot_cmp').setup()
        end,
      },
      -- Additon to lualine to show copilot status
      {
        'AndreM222/copilot-lualine',
        -- enable = true,
        -- Edit lualine setup to include copilot in the statusline
        config = function()
          -- Ensure lualine is loaded before setting up
          local statusline = require 'lualine'
          if not statusline then
            return
          end
        end,
      },
      {
        'CopilotC-Nvim/CopilotChat.nvim',
        -- enable = true,
        -- Variable
        dependencies = {
          { 'github/copilot.vim' }, -- or zbirenbaum/copilot.lua
          { 'nvim-lua/plenary.nvim', branch = 'master' }, -- for curl, log and async functions
        },
        build = 'make tiktoken', -- Only on MacOS or Linux
        opts = {
          -- Shared config starts here (can be passed to functions at runtime and configured via setup function)

          -- system_prompt = 'COPILOT_INSTRUCTIONS', -- System prompt to use (can be specified manually in prompt via /).

          -- vim.keymap.set('n', '<leader>cc', function()
          --   require('CopilotChat').toggle()
          -- end, { desc = 'Toggle Copilot [c]hat' }), -- Keybinding to open Copilot Chat
          vim.keymap.set('n', '<leader>cct', '<cmd>CopilotChatToggle<cr>', { desc = 'Toggle Copilot [c]chat [t]oggle' }),
          vim.keymap.set('n', '<leader>ccm', '<cmd>CopilotChatModels<cr>', { desc = 'Select Copilot [c]hat [m]odel' }),
          vim.keymap.set('n', '<leader>ccr', '<cmd>CopilotChatReset<cr>', { desc = 'Select Copilot [c]hat [r]eset' }),
          model = copilotModel, -- Default model to use, see ':CopilotChatModels' for available models (can be specified manually in prompt via $).
          agent = 'copilot', -- Default agent to use, see ':CopilotChatAgents' for available agents (can be specified manually in prompt via @).
          context = 'file', -- Default context or array of contexts to use (can be specified manually in prompt via #).
          -- sticky = nil, -- Default sticky prompt or array of sticky prompts to use at start of every new chat.
          --
          -- temperature = 0.1, -- GPT result temperature
          -- headless = false, -- Do not write to chat buffer and use history (useful for using custom processing)
          -- stream = nil, -- Function called when receiving stream updates (returned string is appended to the chat buffer)
          -- callback = nil, -- Function called when full response is received (retuned string is stored to history)
          -- remember_as_sticky = true, -- Remember model/agent/context as sticky prompts when asking questions

          -- default window options
          window = {
            layout = 'vertical', -- 'vertical', 'horizontal', 'float', 'replace', or a function that returns the layout
            width = 0.3, -- fractional width of parent, or absolute width in columns when > 1
            height = 0.3, -- fractional height of parent, or absolute height in rows when > 1
            -- Options below only apply to floating windows
            -- relative = 'editor', -- 'editor', 'win', 'cursor', 'mouse'
            border = 'single', -- Add a border to the floating window
            row = nil, -- row position of the window, default is centered
            col = nil, -- column position of the window, default is centered
            title = 'Copilot Chat', -- Add a title to the chat window
            footer = copilotModel, -- Show current model in footer
            zindex = 1, -- determines if window is on top or below other floating windows
          },
          -- default mappings
          -- see config/mappings.lua for implementation
          mappings = {
            complete = {
              insert = '<Tab>',
            },
            close = {
              normal = 'q',
              insert = '<C-c>',
            },
            reset = {
              normal = '',
              insert = '',
            },
            submit_prompt = {
              normal = '<CR>',
              insert = '<C-s>',
            },
            toggle_sticky = {
              normal = 'grr',
            },
            clear_stickies = {
              normal = 'grx',
            },
            accept_diff = {
              normal = '<C-y>',
              insert = '<C-y>',
            },
            jump_to_diff = {
              normal = 'gj',
            },
            quickfix_answers = {
              normal = 'gqa',
            },
            quickfix_diffs = {
              normal = 'gqd',
            },
            yank_diff = {
              normal = 'gy',
              register = '"', -- Default register to use for yanking
            },
            show_diff = {
              normal = 'gd',
              full_diff = false, -- Show full diff instead of unified diff when showing diff window
            },
            show_info = {
              normal = 'gi',
            },
            show_context = {
              normal = 'gc',
            },
            show_help = {
              normal = 'gh',
            },
          },
          -- See Configuration section for options
        },
        -- end,
      },
    },
  },
}
