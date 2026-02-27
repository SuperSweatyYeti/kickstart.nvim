return {
  'folke/noice.nvim',
  enabled = true,
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'rcarriga/nvim-notify',
  },
  config = function()
    vim.g.noice_enabled = true
    local original_notify = nil

    require('noice').setup {
      notify = {
        enabled = false,
      },
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },
    }

    require('which-key').add {
      { mode = { 'n' }, { '<leader>n', group = '[n]oice plugin notifcations', hidden = false } },
    }

    vim.keymap.set(
      'n',
      '<leader>nc',
      '<cmd>NoiceDismiss<enter>',
      { desc = '[c]lear all [n]oice plugin notifications' }
    )

    vim.keymap.set('n', '<leader>nd', '<cmd>NoiceDisable<enter>', { desc = '[d]isable [n]oice notifications' })

    vim.keymap.set('n', '<leader>nt', function()
      if vim.g.noice_enabled then
        vim.cmd 'NoiceDismiss'
        require('notify').dismiss { silent = true, pending = true }
        vim.cmd 'NoiceDisable'
        vim.g.noice_enabled = false
        original_notify = vim.notify
        vim.notify = function() end
        print 'Noice disabled'
      else
        if original_notify then
          vim.notify = original_notify
          original_notify = nil
        end
        vim.cmd 'NoiceEnable'
        vim.g.noice_enabled = true
        vim.notify('Noice enabled', vim.log.levels.INFO)
      end
    end, { desc = '[t]oggle [n]oice notifications' })
  end,
}
