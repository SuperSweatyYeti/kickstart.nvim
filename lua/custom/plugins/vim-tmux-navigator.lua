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
      vim.g.tmux_navigator_no_mappings = 1
    end,
    config = function()
      local path = vim.fn.glob(vim.fn.expand('~/.config/herdr/plugins/github/vim-herdr-navigation-*/editor/nvim.lua'))
      if path ~= '' then
        dofile(path)
      end
    end,
  },
}
