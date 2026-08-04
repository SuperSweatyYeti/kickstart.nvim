return {
  -- {
  --   'christoomey/vim-tmux-navigator',
  --   enabled = true,
  --   cmd = {
  --     'TmuxNavigateLeft',
  --     'TmuxNavigateDown',
  --     'TmuxNavigateUp',
  --     'TmuxNavigateRight',
  --     'TmuxNavigatePrevious',
  --     'TmuxNavigatorProcessList',
  --   },
  --   keys = {
  --     { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
  --     { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
  --     { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
  --     { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
  --     { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
  --   },
  -- },
  -- NOTE: nvim herdr navigator
  {
    'christoomey/vim-tmux-navigator',
    lazy = false,

    init = function()
      -- Prevent plugin from creating automatic mappings.
      -- We will define them ourselves.
      vim.g.tmux_navigator_no_mappings = 1
    end,

    config = function()
      if is_os_windows() then
        -- Windows: native Neovim pane navigation
        vim.keymap.set('n', '<C-h>', '<C-w>h', { silent = true })
        vim.keymap.set('n', '<C-j>', '<C-w>j', { silent = true })
        vim.keymap.set('n', '<C-k>', '<C-w>k', { silent = true })
        vim.keymap.set('n', '<C-l>', '<C-w>l', { silent = true })

        return
      end

      -- Non-Windows: try Herdr first
      local herdr_path = vim.fn.glob(vim.fn.expand('~/.config/herdr/plugins/github/vim-herdr-navigation-*/editor/nvim.lua'))

      if herdr_path ~= '' then
        -- Herdr navigation
        dofile(herdr_path)

        return
      end

      -- Non-Windows + no Herdr:
      -- Explicit vim-tmux-navigator mappings
      vim.keymap.set('n', '<C-h>', '<cmd><C-U>TmuxNavigateLeft<cr>', { silent = true })
      vim.keymap.set('n', '<C-j>', '<cmd><C-U>TmuxNavigateDown<cr>', { silent = true })
      vim.keymap.set('n', '<C-k>', '<cmd><C-U>TmuxNavigateUp<cr>', { silent = true })
      vim.keymap.set('n', '<C-l>', '<cmd><C-U>TmuxNavigateRight<cr>', { silent = true })
      vim.keymap.set('n', '<C-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>', { silent = true })
    end,
  },
}
