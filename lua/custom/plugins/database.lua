return {
  {
    'tpope/vim-dadbod',
    enabled = true,
    opt = true,
    dependencies = {
      'tpope/vim-dadbod',
      'kristijanhusak/vim-dadbod-completion',
      {
        'kristijanhusak/vim-dadbod-ui',
        dependencies = {
          { 'tpope/vim-dadbod', lazy = true },
          { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql', 'mariadb' }, lazy = true },
        },
        cmd = {
          'DBUI',
          'DBUIToggle',
          'DBUIAddConnection',
          'DBUIFindBuffer',
        },
        init = function()
          -- Your DBUI configuration
          vim.g.db_ui_use_nerd_fonts = 1
          vim.keymap.set('n', '<leader>du', '<cmd>DBUIToggle<CR>', { desc = 'Database UI [t]oggle' })
        end,
      },
    },
    config = function()
      require('custom.plugin-configs.database').setup()
    end,
  },
}
