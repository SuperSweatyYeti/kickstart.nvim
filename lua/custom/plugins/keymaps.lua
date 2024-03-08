return {
  {
    ------------------ Custom Keymaps ---------------------------------
    -- Easier to change back to normal mode 'Double tap i'
    vim.keymap.set({ 'v', 'i' }, 'ii', '<Esc><Esc>', {}),
    -- Quickly get to end and beggining of line
    vim.keymap.set('n', '<S-h>', '<Home>', {}),
    vim.keymap.set('n', '<S-l>', '<End>', {}),
    -- vim.keymap.set('v', 'ii', "<Esc>", {})
    -- Easier to navigate between panes
    vim.keymap.set('n', '<C-h>', '<C-w>h', {}),
    vim.keymap.set('n', '<C-j>', '<C-w>j', {}),
    vim.keymap.set('n', '<C-k>', '<C-w>k', {}),
    vim.keymap.set('n', '<C-l>', '<C-w>l', {}),
    -- Resize panes with hjkl
    vim.keymap.set('n', '<A-h>', '<C-w><', {}),
    vim.keymap.set('n', '<A-j>', '<C-w>+', {}),
    vim.keymap.set('n', '<A-k>', '<C-w>-', {}),
    vim.keymap.set('n', '<A-l>', '<C-w>>', {}),
    -- Change tabs with hjkl
    vim.keymap.set('n', '<leader>Th', ':BufferLineCycleNext\n', {}),
    vim.keymap.set('n', '<leader>Tl', ':BufferLineCyclePrev\n', {}),
    vim.keymap.set('n', '<leader>bco', ':BufferLineCloseOthers\n', {}),
    vim.keymap.set('n', '<A-L>', ':BufferLineCycleNext\n', {}),
    vim.keymap.set('n', '<A-H>', ':BufferLineCyclePrev\n', {}),
    --
    -- Pane Splits
    --
    -- Split Vertical
    vim.keymap.set('n', '<leader>Sv', ':vsplit\n', {}),
    -- Split Horizontal
    vim.keymap.set('n', '<leader>Sh', ':split\n', {}),
    ------------------ END Custom Keymaps -----------------------------
  },
}
