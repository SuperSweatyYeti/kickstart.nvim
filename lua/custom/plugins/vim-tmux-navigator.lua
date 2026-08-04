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
  -- NOTE: nvim herdr navigator
  {
    'christoomey/vim-tmux-navigator',
    lazy = false,
    config = function()
      local path = vim.fn.glob(vim.fn.expand('~/.config/herdr/plugins/github/vim-herdr-navigation-*/editor/nvim.lua'))

      if path ~= '' then
        -- Herdr exists, disable default tmux navigator mappings
        vim.g.tmux_navigator_no_mappings = 1

        dofile(path)
      else
        -- Herdr missing, restore normal vim-tmux-navigator mappings
        vim.keymap.set('n', '<C-h>', '<cmd><C-U>TmuxNavigateLeft<cr>', { silent = true })
        vim.keymap.set('n', '<C-j>', '<cmd><C-U>TmuxNavigateDown<cr>', { silent = true })
        vim.keymap.set('n', '<C-k>', '<cmd><C-U>TmuxNavigateUp<cr>', { silent = true })
        vim.keymap.set('n', '<C-l>', '<cmd><C-U>TmuxNavigateRight<cr>', { silent = true })
        vim.keymap.set('n', '<C-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>', { silent = true })
      end
    end,
  },
}
