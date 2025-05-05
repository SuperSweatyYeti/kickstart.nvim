return {
  {
    ------------------ Custom Keymaps ---------------------------------
    -- Easier to change back to normal mode 'Double tap i'
    vim.keymap.set({ 'v', 'i' }, 'ii', '<Esc><Esc>', { desc = 'escape mode' }),
    -- Quickly get to end and beggining of line
    vim.keymap.set({ 'n', 'v' }, '<S-h>', '<Home>', {}),
    vim.keymap.set({ 'n', 'v' }, '<S-l>', '<End>', {}),
    -- vim.keymap.set('v', 'ii', "<Esc>", {})
    -- Easier to navigate between panes
    vim.keymap.set({ 'n', 'v' }, '<C-h>', '<C-w>h', {noremap = true}),
    vim.keymap.set({ 'n', 'v' }, '<C-j>', '<C-w>j', {noremap = true}),
    vim.keymap.set({ 'n', 'v' }, '<C-k>', '<C-w>k', {noremap = true}),
    vim.keymap.set({ 'n', 'v' }, '<C-l>', '<C-w>l', {noremap = true}),
    -- Resize panes with hjkl
    vim.keymap.set({ 'n', 'v' }, '<A-h>', '<C-w><', {noremap = true}),
    vim.keymap.set({ 'n', 'v' }, '<A-j>', '<C-w>+', {noremap = true}),
    vim.keymap.set({ 'n', 'v' }, '<A-k>', '<C-w>-', {noremap = true}),
    vim.keymap.set({ 'n', 'v' }, '<A-l>', '<C-w>>', {noremap = true}),
    -- Change tabs with hjkl
    vim.keymap.set({ 'n', 'v' }, '<leader>Th', ':tabNext\n', {}),
    vim.keymap.set({ 'n', 'v' }, '<leader>Tl', ':tabPrevious\n', {}),
    -- Map <leader>/ to search for the visual selection
    vim.api.nvim_set_keymap('v', '<leader>/', 'y/<C-r>"<CR>', { noremap = true, silent = true }),

    -- vim.keymap.set('n', '<A-L>', ':tabNext\n', {}),
    -- vim.keymap.set('n', '<A-H>', ':tabPrevious\n', {}),
    --
    -- Pane Splits
    --
    -- Split Vertical
    vim.keymap.set('n', '<leader>Sv', ':vsplit\n', { desc = 'Split pane [v]ertically' }),
    -- Split Horizontal
    vim.keymap.set('n', '<leader>Sh', ':split\n', { desc = 'Split pane [h]orizontally' }),
  },
}
