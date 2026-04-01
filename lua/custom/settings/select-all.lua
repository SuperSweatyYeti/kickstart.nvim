-- Keymap to visually select everything in the current buffer
vim.keymap.set('n', '<leader>va', 'ggVG', { noremap = true, desc = '[v]isually select [a]ll text from current buffer' })
-- Keymap to delete everything in the current buffer
vim.keymap.set('n', '<leader>vad', 'ggVGd', { noremap = true, desc = '[v]isually select [a]ll text from current buffer and [d]elete' })
-- Keymap to yank everything in the current buffer
-- vim.keymap.set('n', '<leader>vay', function()
--   local win = 0
--   local pos = vim.api.nvim_win_get_cursor(win)
--   vim.cmd 'normal! ggVGy'
--   vim.api.nvim_win_set_cursor(win, pos)
-- end, { desc = '[v]isually select [a]ll text from current buffer and [y]ank' })
--
--
-- Keymap to yank everything in the current buffer V2
-- Add which-key-group
require('which-key').add {
  { mode = { 'n' }, { '<leader>v', group = '[v]isual selection', hidden = false } },
}
vim.keymap.set('n', '<leader>vay', function()
  vim.cmd('%y')
end, { desc = '[v]isually select [a]ll text from current buffer and [y]ank' })
