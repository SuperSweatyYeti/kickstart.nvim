return {
  'MeanderingProgrammer/render-markdown.nvim',
  opts = {
    file_types = { 'markdown', 'Avante' },
    language_map = {
      powershell = 'ps1',
    },
    on = {
      render = function(ctx)
        -- Restore bold/italic highlights when rendering is on
        vim.api.nvim_set_hl(ctx.buf, '@markup.strong.markdown_inline', { fg = '#e5c07b', bold = true })
        vim.api.nvim_set_hl(ctx.buf, '@markup.italic.markdown_inline', { fg = '#c678dd', italic = true })
      end,
      clear = function(ctx)
        -- Remove bold/italic highlights when rendering is off
        vim.api.nvim_set_hl(ctx.buf, '@markup.strong.markdown_inline', {})
        vim.api.nvim_set_hl(ctx.buf, '@markup.italic.markdown_inline', {})
      end,
    },
    checkbox = {
      enabled = true,
      unchecked = {
        icon = '󰄱',
        highlight = 'RenderMarkdownUnchecked',
      },
      checked = {
        icon = '󰄲',
        highlight = 'RenderMarkdownChecked',
      },
    },
  },
  ft = { 'markdown', 'Avante' },
  config = function(_, opts)
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

    require('render-markdown').setup(opts)

    -- Keymaps
    vim.keymap.set('n', '<leader>mr', '<cmd>RenderMarkdown toggle<CR>', { desc = '[m]arkdown [r]ender toggle', noremap = true, silent = true })
    vim.keymap.set('n', '<leader>mc', function()
      local line = vim.api.nvim_get_current_line()
      local new_line
      if line:match '%- %[ %]' then
        new_line = line:gsub('%- %[ %]', '- [x]', 1)
      elseif line:match '%- %[x%]' then
        new_line = line:gsub('%- %[x%]', '- [ ]', 1)
      else
        return -- not a checkbox line, do nothing
      end
      vim.api.nvim_set_current_line(new_line)
    end, { desc = '[m]arkdown toggle [c]heckbox', noremap = true, silent = true })

    require('which-key').add {
      { mode = { 'n' }, { '<leader>m', group = '[m]arkdown', hidden = false } },
    }
  end,
}
