-- Plugin to allow comprehension of code inside code blocks
-- from markdown files
return {
  {
    'jmbuhr/otter.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {
      -- buffers = {
      --   set_filetype = true,
      --   write_to_disk = true, -- makes otter write real .ps1 files so lspconfig can attach
      -- },
      extensions = {
        -- powershell is not built-in, so we register it here
        ps1 = 'ps1',
        powershell = 'ps1', -- so ```powershell fences also work
      },
    },
    config = function(_, opts)
      require('otter').setup(opts)

      -- Auto-activate otter for markdown files
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'markdown', 'quarto' },
        callback = function()
          require('otter').activate { 'python', 'bash', 'ps1', 'powershell', 'javascript', 'rust', 'zig' }
        end,
      })
    end,
  },
}
