-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {

  -- ToggleTerm
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      --[[ things you want to change go here]]
      vim.keymap.set('t', 'ii', [[<C-\><C-n>]]),
      vim.keymap.set('n', '<leader>t', [[:ToggleTerm<enter>]]),
      vim.keymap.set('t', '<C-k>', [[<C-\><C-n><C-w>k]], {}),
      vim.keymap.set('t', '<C-h>', [[<C-\><C-n><C-w>h]], {}),
    },
  },

  -- Neo-Tree file pane

  -- -- Side Folder Navigation Nvim Tree
  -- {
  --   'nvim-tree/nvim-tree.lua',
  --   version = '*',
  --   api = require 'nvim-tree.api',
  --   opts = {
  --     -- See top of file need to disable netrw
  --     vim.keymap.set('n', '<leader>f', [[:NvimTreeToggle<enter>]]),
  --   },
  -- },
  -- -- Side Folder Navigation Nvim Tree ICONS
  -- { 'nvim-tree/nvim-web-devicons', version = '*', opts = {} },

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
    vim.keymap.set('n', '<leader>Th', ':tabprevious\n', {}),
    vim.keymap.set('n', '<leader>Tl', ':tabnext\n', {}),
    vim.keymap.set('n', '<A-L>', ':tabnext\n', {}),
    vim.keymap.set('n', '<A-H>', ':tabprevious\n', {}),

    ------------------ END Custom Keymaps -----------------------------
  },
}
