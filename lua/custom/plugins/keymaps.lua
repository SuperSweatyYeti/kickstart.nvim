return {
  {
    ------------------ Custom Keymaps ---------------------------------
    -- Quick exit without saving
    vim.keymap.set({ 'n' }, '<leader>QQ', '<cmd>qa!<enter>', { desc = '[Q]uit Quit without saving' }),
    -- Easier to change back to normal mode 'Double tap i'
    -- Insert mode escape
    vim.keymap.set('i', 'JJ', '<Esc><Esc>', { noremap = true, silent = true, desc = 'Escape insert mode' }),
    -- Visual mode escape
    vim.keymap.set('v', 'JJ', '<Esc><Esc>', { noremap = true, silent = true, desc = 'Escape visual mode' }),
    -- Visual block (x) mode escape
    vim.keymap.set('x', 'JJ', '<Esc><Esc>', { noremap = true, silent = true, desc = 'Escape visual block mode' }),
    -- Command (c) mode escape
    vim.keymap.set('c', 'JJ', '<Esc><Esc>', { noremap = true, silent = true, desc = 'Escape Command mode' }),
    -- ONLY EVER Paste last Yank
    vim.keymap.set({ 'n', 'v' }, 'p', '"0p', { noremap = true, silent = true, desc = 'Paste last yank' }),
    -- Normal mode 'x': delete char into register 0 'last yank'
    vim.keymap.set('n', 'x', function()
      vim.cmd 'normal! "0x'
    end, { noremap = true, silent = true }),
    -- Visual mode 'x': delete selection into register 0 'last yank'
    vim.keymap.set('x', 'x', function()
      vim.cmd 'normal! "0d'
    end, { noremap = true, silent = true }),

    vim.keymap.set('x', 'JJ', '<Esc><Esc>', { noremap = true, silent = true, desc = 'Escape visual block mode' }),
    -- Quickly get to end and beggining of line
    vim.keymap.set({ 'n', 'v' }, '<S-h>', '<Home>', {}),
    vim.keymap.set({ 'n', 'v' }, '<S-l>', '<End>', {}),
    -- vim.keymap.set('v', 'JJ', "<Esc>", {})
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
    vim.keymap.set({ 'n', 'v' }, '<leader>Tl', '<Cmd>tabnext<CR>', {}),
    vim.keymap.set({ 'n', 'v' }, '<leader>Th', '<Cmd>tabprevious<CR>', {}),
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
    -- Print filepath for current buffer
    vim.keymap.set('n', '<leader>pwbfo', function()
      print(vim.fn.expand '%:p')
    end, { desc = '[p]rint [w]orking [b]uffer [f]ilepath [o]utput' }),

    vim.keymap.set('n', '<leader>pwbfc', function()
      vim.fn.setreg('+', vim.fn.expand '%:p')
    end, { desc = '[p]rint [w]orking [b]uffer [f]ilepath to [c]lipboard' }),

    vim.keymap.set('n', '<leader>pwbFo', function()
      print(vim.fn.expand '%:p:h')
    end, { desc = '[p]rint [w]orking [b]uffer [F]older [o]utput' }),

    vim.keymap.set('n', '<leader>pwbFc', function()
      vim.fn.setreg('+', vim.fn.expand '%:p:h')
    end, { desc = '[p]rint [w]orking [b]uffer [F]older to [c]lipboard' }),
    -- =======================================
    -- Buffer Actions
    -- =======================================
    -- Easier to close buffer
    vim.keymap.set('n', '<leader>C', '<cmd>q<CR>', { desc = '[C]lose Buffer' }),
    -- Easier to refresh current buffer
    vim.keymap.set('n', '<leader>br', '<cmd>e!<CR>', { desc = '[r]efresh Buffer discard buffer changes' }),
    -- Easier to refresh current ALL buffers
    vim.keymap.set('n', '<leader>bR', '<cmd>bufdo e<CR>', { desc = '[r]efresh ALL Buffers check for file updates' }),
    -- Easier to delete buffer
    -- Actually sends buffer wipeout command
    vim.keymap.set('n', '<leader>bd', '<cmd>bw<CR>', { desc = '[d]elete buffer' }),
    vim.keymap.set('n', '<leader>bD', '<cmd>bw!<CR>', { desc = '[D]elete buffer [F]orce' }),
    -- Step back and forth through buffer history
    vim.keymap.set('n', '<leader>bn', '<cmd>bNext<CR>', { desc = '[n]ext buffer' }),
    vim.keymap.set('n', '<leader>bp', '<cmd>bprevious<CR>', { desc = '[p]revious buffer' }),
    -- Diagnostic keymaps
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [d]iagnostic message' }),
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [d]iagnostic message' }),
    vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [e]rror messages' }),
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [q]uickfix list' }),
  },
}
