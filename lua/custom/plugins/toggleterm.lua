return {
  -- ToggleTerm
  {
    'akinsho/toggleterm.nvim',
    enabled = true,
    version = '*',
    opts = {
      --[[ things you want to change go here]]
      -- Default Shell for if on Windows
      shell = function()
        if is_os_windows() then
          return vim.fn.executable 'pwsh' == 1 and 'pwsh' or 'powershell'
        end
        -- Linux/macOS: zsh → bash → sh
        if vim.fn.executable 'zsh' == 1 then
          return 'zsh'
        elseif vim.fn.executable 'bash' == 1 then
          return 'bash'
        end
        return 'sh'
      end,

      vim.keymap.set('t', 'JJ', [[<C-\><C-n>]]),
      vim.keymap.set('n', '<leader>t', [[:ToggleTerm<enter>]], { desc = 'ToggleTerm' }),
      vim.keymap.set('t', '<C-k>', [[<C-\><C-n><C-w>k]], {}),
      vim.keymap.set('t', '<C-h>', [[<C-\><C-n><C-w>h]], {}),
    },
    config = function(_, opts)
      require('toggleterm').setup(opts)
      
    end,
  },
}
