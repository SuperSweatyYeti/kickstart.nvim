return {
  'MeanderingProgrammer/render-markdown.nvim',
  opts = {
    file_types = { 'markdown', 'Avante' },
    language_map = {
      -- NOTE: Add config to have markdown code block reconize code blocks for powershell
      -- ```powershell
      -- Get-Funciton
      -- ```
      --
      -- Config to add code block code recognition
      -- Here
      powershell = 'ps1',
    },
  },
  ft = { 'markdown', 'Avante' },
  -- Config to add code block code recognition
  -- Here
  config = function()
    require('nvim-web-devicons').set_icon {
      -- Config to add code block code recognition
      -- Here
      ps1 = {
        icon = '󰨊',
        color = '#4273ca',
        name = 'Powershell',
      },
    }
    require('nvim-web-devicons').set_icon_by_filetype {
      -- Config to add code block code recognition
      -- Here
      powershell = 'ps1',
    }

    -- Keymaps
    vim.keymap.set('n', '<leader>mr', '<cmd>RenderMarkdown toggle<CR>', { desc = '[m]arkdown [r]ender toggle', noremap = true, silent = true })
    require('which-key').add {
      { mode = { 'n' }, { '<leader>m', group = '[m]arkdown', hidden = false } },
    }
  end,
}
