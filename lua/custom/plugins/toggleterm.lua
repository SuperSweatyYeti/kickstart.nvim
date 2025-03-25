return {
  -- ToggleTerm
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      --[[ things you want to change go here]]
      vim.keymap.set('t', 'ii', [[<C-\><C-n>]]),
      vim.keymap.set('n', '<leader>t', [[:ToggleTerm<enter>]], {desc = 'ToggleTerm'}),
      vim.keymap.set('t', '<C-k>', [[<C-\><C-n><C-w>k]], {}),
      vim.keymap.set('t', '<C-h>', [[<C-\><C-n><C-w>h]], {}),
    },
  },
}
