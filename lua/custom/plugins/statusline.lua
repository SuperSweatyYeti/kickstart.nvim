return {
  -- lualine
  {
    'nvim-lualine/lualine.nvim',
    enabled = true,
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    options = { theme = 'tokyonight' },
    config = function()
      -- Define the statusline function for showing our custom yank behavior toggle
      -- defined in lua/settings/yank-config.lua

      function preserve_yank_status()
        if vim.g.preserve_yank_enabled == true then
          return '📋' -- Display the clipboard icon when enabled
        else
          return '' -- Return nothing when it's disabled
        end
      end

      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'auto',
          component_separators = { left = '|', right = '|' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = {
            statusline = {},
            winbar = {},
          },
          ignore_focus = {},
          always_divide_middle = true,
          globalstatus = true,
          refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
          },
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff' }, -- 'diagnostics'
          lualine_c = { 'filename' },
          lualine_x = {
            -- 'copilot',
            -- Copilot / AI status
            {
              function()
                local ok, copilot_client = pcall(require, 'copilot.client')
                if not ok then
                  return ' '
                end

                if copilot_client.is_disabled() then
                  return ' '
                end

                if not copilot_client.get() then
                  return ' '
                end

                local ok2, copilot_status = pcall(require, 'copilot.status')
                if not ok2 then
                  return ''
                end

                local status = copilot_status.data and copilot_status.data.status or ''
                local icons = {
                  ['']   = ' ' ,
                  Normal = ' ', -- ready
                  InProgress = '  ', -- working / thinking
                  Warning = ' ', -- warning / degraded
                  Offline = ' ', -- offline / disabled
                  Unknown = ' ',
                }

                return icons[status] or icons.Unknown
              end,
              -- -- Optional function to set colors
              -- color = function()
              --   local ok, copilot_api = pcall(require, 'copilot.api')
              --   if not ok then
              --     return {}
              --   end
              --
              --   local status = copilot_api.status.data and copilot_api.status.data.status or 'Normal'
              --
              --   local colors = {
              --     Normal = { fg = '#6CC644' }, -- green
              --     InProgress = { fg = '#E5C07B' }, -- yellow
              --     Warning = { fg = '#E06C75' }, -- red
              --     Offline = { fg = '#5C6370' }, -- grey
              --     Unknown = { fg = '#5C6370' },
              --   }
              --
              --   return colors[status] or colors.Unknown
              -- end,
            },
            {
              function()
                return preserve_yank_status()
              end,
            },
            'encoding',
            'fileformat',
            'filetype',
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { 'filename' },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {},
      }
    end,
  },
}
