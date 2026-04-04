-- Keymap to visually select everything in the current buffer
vim.keymap.set('n', '<leader>vaa', 'ggVG', { noremap = true, desc = '[v]isually select [a]ll text from current buffer' })
-- Keymap to delete everything in the current buffer AND DON'T clobber system clipboard add to yank history instead
vim.keymap.set('n', '<leader>vad', function()
  local prev_contents = vim.fn.getreg '"'
  local prev_type = vim.fn.getregtype '"'

  local has_clipboard = vim.fn.has 'clipboard' == 1
  local prev_plus, prev_plus_type, prev_star, prev_star_type
  if has_clipboard then
    prev_plus = vim.fn.getreg '+'
    prev_plus_type = vim.fn.getregtype '+'
    prev_star = vim.fn.getreg '*'
    prev_star_type = vim.fn.getregtype '*'
  end

  vim.cmd 'normal! ggVGd'

  local deleted_contents = vim.fn.getreg '"'
  local deleted_type = vim.fn.getregtype '"'

  vim.fn.setreg('1', deleted_contents, deleted_type)
  vim.fn.setreg('"', prev_contents, prev_type)

  if has_clipboard then
    vim.fn.setreg('+', prev_plus, prev_plus_type)
    vim.fn.setreg('*', prev_star, prev_star_type)
  end
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
