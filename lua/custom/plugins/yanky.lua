return {
  -- Yank history
  {
    'gbprod/yanky.nvim',
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      vim.keymap.set('n', '<Leader>yh', [[<cmd>YankyRingHistory<CR>]], {}),
      vim.keymap.set('n', '<Leader>p', [[<cmd>YankyRingHistory<CR>]], {}),
    },
  },
}
