return {
  'roobert/search-replace.nvim',
  enabled = true,
  config = function()
    require('search-replace').setup {
      -- optionally override defaults
      default_replace_single_buffer_options = 'gc',
      default_replace_multi_buffer_options = 'egc',
    }
    -- show the effects of a search / replace in a live preview window
    vim.o.inccommand = 'split'
    -- Which-Key Keychains
    require('which-key').add {
      { mode = { 'n' }, { '<leader>sR', group = '[R]eplace', hidden = false } },
      { mode = { 'n' }, { '<leader>sRs', group = '[R]eplace on [S]ingle open buffer', hidden = false } },
      { mode = { 'n' }, { '<leader>sRm', group = '[R]eplace on [M]ultiple open buffers', hidden = false } },
    }
    -- Keymaps
    vim.keymap.set(
      { 'n', 'x' },
      '<leader>sRs',
      '<CMD>SearchReplaceSingleBufferOpen<CR>',
      { noremap = true, silent = true, desc = 'Search and Replace on current open buffer' }
    )
    vim.keymap.set(
      { 'n', 'x' },
      '<leader>sRm',
      '<CMD>SearchReplaceMultiBufferOpen<CR>',
      { noremap = true, silent = true, desc = 'Search and Replace on current open buffer' }
    )
    vim.keymap.set(
      { 'n' },
      '<leader>sRR',
      '<leader>sg',
      { noremap = true, silent = true, desc = 'Search and Replace on current open buffer' }
    )
  end,
}
