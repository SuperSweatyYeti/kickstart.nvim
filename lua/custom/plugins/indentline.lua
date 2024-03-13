vim.g.indent_blankline_context_patterns = { 'class', 'function', 'method', 'if', 'while', 'for', 'context' }
return {
  -- Add indentation guides even on blank lines
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {
      scope = {
        enabled = true,
        show_exact_scope = true,
      },
    },
  },
}
