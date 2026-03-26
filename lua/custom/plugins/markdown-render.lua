return {
  'MeanderingProgrammer/render-markdown.nvim',
  opts = {
    file_types = { 'markdown', 'Avante' },
    language_map = {
      powershell = 'ps1',
    },
  },
  ft = { 'markdown', 'Avante' },
  -- Config to add code block code recognition
  config = function()
    require('nvim-web-devicons').set_icon {
      ps1 = {
        icon = '󰨊',
        color = '#4273ca',
        name = 'Powershell',
      },
    }
    require('nvim-web-devicons').set_icon_by_filetype {
      powershell = 'ps1',
    }
  end,
}
