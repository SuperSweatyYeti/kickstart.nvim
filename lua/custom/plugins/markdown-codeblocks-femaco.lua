return {
  'AckslD/nvim-FeMaco.lua',
  enabled = false,
  config = function()
    require('femaco').setup {

      float_opts = function(code_block)
        local width = math.floor(vim.o.columns * 0.80)
        local height = math.floor(vim.o.lines * 0.75)
        local row = math.floor((vim.o.lines - height) / 2)
        local col = math.floor((vim.o.columns - width) / 2)

        return {
          relative = 'editor',
          width = width,
          height = height,
          row = row,
          col = col,
          border = 'rounded',
        }
      end,
    }

    vim.keymap.set('n', '<leader>cb', '<CMD>FeMaco<CR>', { noremap = true, silent = true, desc = '[c]ode [b]lock markdown open in window' })
  end,
}
