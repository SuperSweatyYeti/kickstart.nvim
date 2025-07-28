return {
  {
    ------------------ Custom Keymaps ---------------------------------
    -- Quick exit without saving
    vim.keymap.set({ 'n' }, '<leader>QQ', '<cmd>qa!<enter>', { desc = '[Q]uit quit without saving' }),
    -- Easier to change back to normal mode 'Double tap i'
    -- Insert mode escape
    vim.keymap.set('i', 'ii', '<Esc><Esc>', { noremap = true, silent = true, desc = 'Escape insert mode' }),
    -- Visual mode escape
    vim.keymap.set('v', 'ii', '<Esc><Esc>', { noremap = true, silent = true, desc = 'Escape visual mode' }),
    -- Visual block (x) mode escape
    vim.keymap.set('x', 'ii', '<Esc><Esc>', { noremap = true, silent = true, desc = 'Escape visual block mode' }),
    -- Past and PRESERVE YANK
    vim.keymap.set({ 'x', 'v' }, 'p', [["0p]], { silent = true, desc = 'Paste without overwriting yank' }),

    vim.keymap.set('x', 'ii', '<Esc><Esc>', { noremap = true, silent = true, desc = 'Escape visual block mode' }),
    -- Quickly get to end and beggining of line
    vim.keymap.set({ 'n', 'v' }, '<S-h>', '<Home>', {}),
    vim.keymap.set({ 'n', 'v' }, '<S-l>', '<End>', {}),
    -- vim.keymap.set('v', 'ii', "<Esc>", {})
    -- Better Indenting
    vim.keymap.set({ 'v' }, '<', '<gv', { noremap = true }),
    vim.keymap.set({ 'v' }, '>', '>gv', { noremap = true }),
    -- Easier to navigate between panes
    vim.keymap.set({ 'n', 'v' }, '<C-h>', '<C-w>h', { noremap = true }),
    vim.keymap.set({ 'n', 'v' }, '<C-j>', '<C-w>j', { noremap = true }),
    vim.keymap.set({ 'n', 'v' }, '<C-k>', '<C-w>k', { noremap = true }),
    vim.keymap.set({ 'n', 'v' }, '<C-l>', '<C-w>l', { noremap = true }),
    -- Resize panes with hjkl
    vim.keymap.set({ 'n', 'v' }, '<A-h>', '<C-w><', { noremap = true }),
    vim.keymap.set({ 'n', 'v' }, '<A-j>', '<C-w>+', { noremap = true }),
    vim.keymap.set({ 'n', 'v' }, '<A-k>', '<C-w>-', { noremap = true }),
    vim.keymap.set({ 'n', 'v' }, '<A-l>', '<C-w>>', { noremap = true }),
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
    -- Add empty lines before and after cursor line
    -- before
    vim.keymap.set('n', 'gO', "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>k", { desc = 'Append Line Before' }),
    -- after
    vim.keymap.set('n', 'go', "<Cmd>call append(line('.'), repeat([''], v:count1))<CR>j", { desc = 'Append Line After' }),
  },
}
