-- Open code blocks from markdown files in floating window
return {
  'AckslD/nvim-FeMaco.lua',
  config = 'require("femaco").setup()',
  vim.keymap.set('n', '<leader>cb', '<CMD>FeMaco<CR>', { noremap = true, silent = true, desc = '[c]ode [b]lock markdown open in window' }),
}
