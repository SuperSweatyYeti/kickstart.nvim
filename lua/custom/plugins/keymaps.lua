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
    vim.keymap.set({ 'n', 'v' }, '<C-h>', '<C-w>h', {}),
    vim.keymap.set({ 'n', 'v' }, '<C-j>', '<C-w>j', {}),
    vim.keymap.set({ 'n', 'v' }, '<C-k>', '<C-w>k', {}),
    vim.keymap.set({ 'n', 'v' }, '<C-l>', '<C-w>l', {}),
    -- Resize panes with hjkl
    vim.keymap.set({ 'n', 'v' }, '<A-h>', '<C-w><', {}),
    vim.keymap.set({ 'n', 'v' }, '<A-j>', '<C-w>+', {}),
    vim.keymap.set({ 'n', 'v' }, '<A-k>', '<C-w>-', {}),
    vim.keymap.set({ 'n', 'v' }, '<A-l>', '<C-w>>', {}),
    -- Change tabs with hjkl
    vim.keymap.set({ 'n', 'v' }, '<leader>Th', ':tabNext\n', {}),
    vim.keymap.set({ 'n', 'v' }, '<leader>Tl', ':tabPrevious\n', {}),
    -- vim.keymap.set('n', '<A-L>', ':tabNext\n', {}),
    -- vim.keymap.set('n', '<A-H>', ':tabPrevious\n', {}),
    --
    -- Pane Splits
    --
    -- Split Vertical
    vim.keymap.set('n', '<leader>Sv', ':vsplit\n', { desc = 'Split pane [v]ertically' }),
    -- Split Horizontal
    vim.keymap.set('n', '<leader>Sh', ':split\n', { desc = 'Split pane [h]orizontally' }),

    -- NOTE: Don't overwrite my pasting or changing text buffer when pasting over text in visual mode
    --
    -- PASTING
    vim.keymap.set('v', 'p', function()
      -- Paste now before swapping registers
      vim.cmd 'normal! p'
      local unnamed = vim.fn.getreginfo '"'
      local zero = vim.fn.getreginfo '0'
      -- Swap the contents
      vim.fn.setreg('"', zero.regcontents, zero.regtype)
      vim.fn.setreg('1', unnamed.regcontents, unnamed.regtype)
    end, { desc = 'Swap last yank with previous yank' }),
    -- CHANGE
    vim.keymap.set('v', 'c', function()
      -- Paste now before swapping registers
      vim.cmd 'normal! c'
      local unnamed = vim.fn.getreginfo '"'
      local zero = vim.fn.getreginfo '0'
      -- Swap the contents
      vim.fn.setreg('"', zero.regcontents, zero.regtype)
      vim.fn.setreg('1', unnamed.regcontents, unnamed.regtype)
    end, { desc = 'Swap last yank with previous yank' }),

    -- C MOTIONS
    --
    -- change inner word
    vim.keymap.set('n', 'ciw', function()
      -- Paste now before swapping registers
      vim.cmd 'normal! ciw'
      local unnamed = vim.fn.getreginfo '"'
      local zero = vim.fn.getreginfo '0'
      -- Swap the contents
      vim.fn.setreg('"', zero.regcontents, zero.regtype)
      vim.fn.setreg('1', unnamed.regcontents, unnamed.regtype)
    end, { desc = 'Swap last yank with previous yank' }),

    ------------------ END Custom Keymaps -----------------------------
  },
}
