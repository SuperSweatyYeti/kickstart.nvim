return {
  enabled = is_os_linux(),
  'linux-cultist/venv-selector.nvim',
  dependencies = { 'neovim/nvim-lspconfig', 'nvim-telescope/telescope.nvim', 'mfussenegger/nvim-dap-python' },
  opts = {
    -- Your options go here
    name = '.venv',
    auto_refresh = true,
    stay_on_this_version = true,
  },
  event = 'VeryLazy', -- Optional: needed only if you want to type `:VenvSelect` without a keymapping
  keys = {
    -- Keymap to open VenvSelector to pick a venv.
    { '<leader>Vs', '<cmd>VenvSelect<cr>' },
    -- Keymap to retrieve the venv from a cache (the one previously used for the same project directory).
    { '<leader>Vc', '<cmd>VenvSelectCached<cr>' },
  },
  config = function(_, opts)
    require('which-key').add {
      { mode = { 'n' }, { '<leader>V', group = 'python [V]env selector', hidden = false } },
    }
  end,
}
