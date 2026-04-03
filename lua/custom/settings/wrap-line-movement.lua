-- Config to toggle line movement behavior.
-- By default j and k move up and down 1 line.
-- But if we are dealing with text that has
-- line wrapping we may want different behavior
-- where we go down visually on the same wrapped line.

vim.g.wrap_mode_move = false
vim.api.nvim_create_user_command('WrapModeMoveToggle', function()
  if vim.g.wrap_mode_move == false then
    vim.keymap.set({'n','v','x'}, 'j', 'gj', { noremap = true })
    vim.keymap.set({'n','v','x'}, 'k', 'gk', { noremap = true })
    vim.keymap.set({'n','v','x'}, '0', 'g0', { noremap = true })
    vim.keymap.set({'n','v','x'}, '<S-h>', 'g<Home>', { noremap = true })
    vim.keymap.set({'n','v','x'}, '$', 'g$', { noremap = true })
    vim.keymap.set({'n','v','x'}, '<S-l>', 'g<End>', { noremap = true })
    vim.keymap.set({'n','v','x'}, '<Home>', 'g<Home>', { noremap = true })
    vim.keymap.set({'n','v','x'}, '<End>', 'g<End>', { noremap = true })
    vim.g.wrap_mode_move = true
  elseif vim.g.wrap_mode_move == true then
    vim.keymap.set({'n','v','x'}, 'j', 'j', { noremap = true })
    vim.keymap.set({'n','v','x'}, 'k', 'k', { noremap = true })
    vim.keymap.set({'n','v','x'}, '0', '0', { noremap = true })
    vim.keymap.set({'n','v','x'}, '<S-h>', '<Home>', { noremap = true })
    vim.keymap.set({'n','v','x'}, '$', '$', { noremap = true })
    vim.keymap.set({'n','v','x'}, '<S-l>', '<End>', { noremap = true })
    vim.keymap.set({'n','v','x'}, '<Home>', '<Home>', { noremap = true })
    vim.keymap.set({'n','v','x'}, '<End>', '<End>', { noremap = true })
    vim.g.wrap_mode_move = false
  end
end, { desc = 'Toggle Up/Down movement to visual line instead of actual line' })

-- Prepend wrap mode indicator to lualine section Y
local lualine = require('lualine')
local lualine_config = lualine.get_config()
table.insert(lualine_config.sections.lualine_y, 1, {
  function()
    return '󰖶'
  end,
  cond = function()
    return vim.g.wrap_mode_move == true
  end,
})
lualine.setup(lualine_config)

-- Add which key group
require('which-key').add {
  { mode = { 'n' }, { '<leader>w', group = '[w]rap', hidden = false } },
}
-- Add keymap
vim.keymap.set('n', '<leader>wt', '<CMD>WrapModeMoveToggle<CR>', { noremap = true, desc = '[w]rap mode move [t]oggle' })
