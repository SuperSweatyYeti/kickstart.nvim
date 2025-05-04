return {

  -- Uncomment to format on save
  { -- Autoformat
    'stevearc/conform.nvim',
    enabled = true,
    opts = {
      notify_on_error = true,
      -- format_on_save = {
      --   timeout_ms = 500,
      --   lsp_fallback = true,
      -- },
      formatters_by_ft = {
        lua = { 'stylua' },
        xml = { 'xmlformatter' },
        json = { 'prettier' },
        yaml = { 'yamlfmt' },
        yml = { 'yamlfmt' },
        sh = { 'shfmt' },
        zsh = { 'shfmt' },
        zshrc = { 'shfmt' },
        bash = { 'shfmt' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use a sub-list to tell conform to run *until* a formatter
        -- is found.
        -- javascript = { { "prettierd", "prettier" } },
        --
      },
    },
    keys = {
      {
        -- Customize or remove this keymap to your liking
        '<leader>ff',
        function()
          require('conform').format { async = true, lsp_fallback = true }
        end,
        mode = 'n',
        desc = 'Format buffer',
      },
    },
  },
}
