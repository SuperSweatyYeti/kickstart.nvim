return {

  {
    'mbbill/undotree',
    enabled = true,
    config = function()
      vim.keymap.set('n', '<leader>ut', '<cmd>UndotreeToggle<cr><cmd>UndotreeFocus<cr>', { desc = 'UndotreeToggle' })
    end,
  },
}
