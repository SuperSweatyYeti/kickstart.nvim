return {

  {
    'mbbill/undotree',
    config = function()
      vim.keymap.set('n', '<leader>ut', '<cmd>UndotreeToggle<cr>', { desc = 'Undotree' })
    end,
  },
}
