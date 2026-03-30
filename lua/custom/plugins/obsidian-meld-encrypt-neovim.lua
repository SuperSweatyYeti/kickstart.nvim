return {
  {
    'SuperSweatyYeti/meld-encrypt-neovim',
    version = false,
    enabled = true,
    lazy = true,
    ft = { 'mdenc', 'encrypted' },
    cmd = { 'MeldEncryptEncrypt', 'MeldEncryptDecrypt', 'MeldEncryptEdit' },
    keys = {
      { '<leader>mme', '<CMD>MeldEncryptEdit<CR>', desc = '[m]arkdown [m]eld-encrypt [e]dit' },
    },
    init = function()
      -- Which-key groups (runs at startup, before plugin loads)
      require('which-key').add {
        { mode = { 'n' }, { '<leader>mm', group = '[m]arkdown [m]eld-encrypt', hidden = false } },
      }
    end,
    config = function()
      require('meld-encrypt').setup()
    end,
  },
}
