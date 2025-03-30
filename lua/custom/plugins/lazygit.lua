return {
  {
    'kdheepak/lazygit.nvim',
    enabled = true,
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    -- optional for floating window border decoration
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    keys = {
      vim.keymap.set('n', '<leader>lg', [[:LazyGit<enter>]], { desc = '[L]azyGit' }),
    },
  },
}
