return {
  'MeanderingProgrammer/render-markdown.nvim',
  opts = {
    file_types = { 'markdown', 'Avante' },
    language_map = {
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
  end,
}
