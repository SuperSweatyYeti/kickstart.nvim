return {
  -- NOTE: Plugins can also be configured to run lua code when they are loaded.
  --
  -- This is often very useful to both group configuration, as well as handle
  -- lazy loading plugins that don't need to be loaded immediately at startup.
  --
  -- For example, in the following configuration, we use:
  --  event = 'VimEnter'
  --
  -- which loads which-key before all the UI elements are loaded. Events can be
  -- normal autocommands events (`:help autocmd-events`).
  --
  -- Then, because we use the `config` key, the configuration only runs
  -- after the plugin has been loaded:
  --  config = function() ... end

  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    enabled = true,
    event = 'vimenter', -- sets the loading event to 'vimenter'
    config = function() -- this is the function that runs, after loading
      require('which-key').setup()

      -- document existing key chains
      require('which-key').add {
        { mode = { 'n' }, { '<leader>S', group = '[S]plits', hidden = false } },
        { mode = { 'n', 'v' }, { '<leader>R', group = 'Snip[R]un', hidden = false } },
        --{ mode = {'n'}, { '<leader>R', group = 'Snip [R]un', hidden = false }, }, { mode = {'n'}, { '<leader>T', group = '[T]abs', hidden = false }, },
        { mode = { 'n' }, { '<leader>l', group = '[l]sp', hidden = false } },
        { mode = { 'n' }, { '<leader>b', group = '[b]uffers', hidden = false } },
        { mode = { 'n' }, { '<leader>c', group = '[c]ode', hidden = false } },
        { mode = { 'n' }, { '<leader>d', group = '[d]ocument', hidden = false } },
        { mode = { 'n' }, { '<leader>l', group = '[l]azyGit', hidden = false } },
        { mode = { 'n' }, { '<leader>Q', group = '[Q]uit quit', hidden = false } },
        { mode = { 'n' }, { '<leader>r', group = '[r]ename', hidden = false } },
        { mode = { 'n' }, { '<leader>s', group = '[s]earch', hidden = false } },
        { mode = { 'n' }, { '<leader>u', group = '[u]ndo', hidden = false } },
        { mode = { 'n' }, { '<leader>w', group = '[w]orkspace', hidden = false } },
        { mode = { 'n' }, { '<leader>y', group = '[y]ank', hidden = false } },
        -- OLD Spec
        -- ['<leader>c'] = { name = '[c]ode', _ = 'which_key_ignore' },
        -- ['<leader>d'] = { name = '[d]ocument', _ = 'which_key_ignore' },
        -- ['<leader>r'] = { name = '[r]ename', _ = 'which_key_ignore' },
        -- ['<leader>s'] = { name = '[s]earch', _ = 'which_key_ignore' },
        -- ['<leader>w'] = { name = '[w]orkspace', _ = 'which_key_ignore' },
        -- ['<leader>l'] = { name = '[L]azyGit', _ = 'which_key_ignore' },
        -- ['<leader>T'] = { name = '[T]abs', _ = 'which_key_ignore' },
        -- ['<leader>S'] = { name = '[S]plits', _ = 'which_key_ignore' },
        -- ['<leader>u'] = { name = '[u]ndo', _ = 'which_key_ignore' },
        -- ['<leader>y'] = { name = '[y]ank', _ = 'which_key_ignore' },
      }
    end,
    opts = {
      layout = { align = 'center' },
    },
  },
}
