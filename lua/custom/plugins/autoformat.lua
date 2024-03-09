return {

    vim.keymap.set('n', '<leader>ff', ':lua vim.lsp.buf.format()\n', {}),
    -- Uncomment to format on save
    -- { -- Autoformat
    --   'stevearc/conform.nvim',
    --   opts = {
    --     notify_on_error = false,
    --     -- format_on_save = {
    --     --   timeout_ms = 500,
    --     --   lsp_fallback = true,
    --     -- },
    --     vim.keymap.set('n', '<leader>ff', ':lua vim.lsp.buf.format()\n', {}),
    --     formatters_by_ft = {
    --       lua = { 'stylua' },
    --       -- Conform can also run multiple formatters sequentially
    --       -- python = { "isort", "black" },
    --       --
    --       -- You can use a sub-list to tell conform to run *until* a formatter
    --       -- is found.
    --       -- javascript = { { "prettierd", "prettier" } },
    --       --
    --     },
    --   },
    -- },
}
