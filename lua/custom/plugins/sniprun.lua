return {
  -- Run code in neovim
  {
    'michaelb/sniprun',
    enabled = true,
    -- branch = 'master',

    build = 'sh install.sh',
    -- do 'sh install.sh 1' if you want to force compile locally
    -- (instead of fetching a binary from the github release). Requires Rust >= 1.65

    config = function()
      require('sniprun').setup {
        -- your options
        vim.keymap.set({ 'n', 'v' }, '<leader>Rl', ':SnipRun<cr>', { desc = 'Snip[R]un [l]ines' }),
        vim.keymap.set('n', '<leader>Ref', '<esc><esc>ggVGG:SnipRun<cr>', { desc = 'Snip[R]un [e]ntire [f]ile' }),
        -- Add which-key group description
        require('which-key').add {
          { mode = { 'n' }, { '<leader>Re', group = 'Snip[R]un [e]ntire ...', hidden = false } },
          { mode = { 'n', 'v' }, { '<leader>R', group = 'Snip[R]un', hidden = false } },
        },
      }
    end,
  },
}
