return {
  'athar-qadri/scratchpad.nvim',
  event = 'VeryLazy',
  opts = {},
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    local scratchpad = require 'scratchpad'
    scratchpad:setup { settings = { sync_on_ui_close = true } }

    require('which-key').add {
      { mode = { 'n' }, { '<leader>sp', group = '[s]cratch [p]ad', hidden = false } },
    }
  end,
  keys = {
    {
      '<Leader>sps',
      function()
        local scratchpad = require 'scratchpad'
        scratchpad.ui:new_scratchpad()
      end,
      desc = '[s]cratch [p]ad show',

      vim.keymap.set({ 'n', 'x' }, '<leader>spp', function()
        local scratchpad = require 'scratchpad'
        scratchpad.ui:sync()
      end, { desc = 'Push selection / current line to [s]cratch [p]ad' }),
    },
  },
}
