-- Config to toggle line movement behavior.
-- By default j and k move up and down 1 line.
-- But if we are dealing with text that has
-- line wrapping we may want different behavior
-- where we go down visually on the same wrapped line.

vim.g.wrap_mode_move = false
vim.api.nvim_create_user_command('WrapModeMoveToggle', function()
  if vim.g.wrap_mode_move == false then
    vim.keymap.set('n', 'j', 'gj', { noremap = true })
    vim.keymap.set('n', 'k', 'gk', { noremap = true })
    vim.g.wrap_mode_move = true
  elseif vim.g.wrap_mode_move == true then
    vim.keymap.set('n', 'j', 'j', { noremap = true })
    vim.keymap.set('n', 'k', 'k', { noremap = true })
    vim.g.wrap_mode_move = false
  end
end, { desc = 'Toggle Up/Down movement to visual line instead of actual line' })

-- Add which key group
require('which-key').add {
  { mode = { 'n' }, { '<leader>w', group = '[w]rap', hidden = false } },
}
-- Add keymap
vim.keymap.set('n', '<leader>wt', '<CMD>WrapModeMoveToggle<CR>', { noremap = true, desc = '[w]rap mode move [t]oggle' })
