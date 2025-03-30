return {
  {
    "FabijanZulj/blame.nvim",
    lazy = false,
    config = function()
      -- Add which key group and keymap
      require('blame').setup {}
      -- document additional key chain
      require('which-key').add {
        { mode = {'n'},{ '<leader>g', group = '[g]it', hidden = false },},
      }

      vim.keymap.set('n', '<leader>gb', ':BlameToggle<CR>', { desc = 'Toggle [g]it [b]lame' })
    end,
    opts = {
      blame_options = { '-w' },
    },
  },
}
-- ## Usage
-- The following commands are used:
-- - `BlameToggle [view]` - Toggle the blame with provided view. If no view is provided it opens the `default` (window) view
--
-- There are two built-in views:
-- - `window` - fugitive style window to the left of the current window
-- - `virtual` - blame shown in a virtual text floated to the right
