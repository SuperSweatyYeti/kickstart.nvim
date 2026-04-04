-- Keymap to visually select everything in the current buffer
vim.keymap.set('n', '<leader>vaa', 'ggVG', { noremap = true, desc = '[v]isually select [a]ll text from current buffer' })
-- Keymap to delete everything in the current buffer AND DON'T clobber system clipboard add to register 1 instead
vim.keymap.set('n', '<leader>vad', function()
  local prev_contents = vim.fn.getreg '"'
  local prev_type = vim.fn.getregtype '"'
  local prev_plus = vim.fn.getreg '+'
  local prev_plus_type = vim.fn.getregtype '+'
  local prev_star = vim.fn.getreg '*'
  local prev_star_type = vim.fn.getregtype '*'

  vim.cmd 'normal! ggVG"_d'

  vim.fn.setreg('"', prev_contents, prev_type)
  vim.fn.setreg('+', prev_plus, prev_plus_type)
  vim.fn.setreg('*', prev_star, prev_star_type)
end, { noremap = true, desc = '[v]isually select [a]ll text from current buffer and [d]elete' })



-- Keymap to yank everything in the current buffer V2
-- Add which-key-group
require('which-key').add {
  { mode = { 'n' }, { '<leader>v', group = '[v]isual selection', hidden = false } },
  { mode = { 'n' }, { '<leader>va', group = '[v]isually select [a]ll', hidden = false } },
}
vim.keymap.set('n', '<leader>vay', function()
  vim.cmd('%y')
end, { desc = '[v]isually select [a]ll text from current buffer and [y]ank' })
