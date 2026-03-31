return {

  -- {
  --   'unblevable/quick-scope',
  --   enabled = true,
  --   -- Quickscope only highlight when f search
  --   init = function()
  --     vim.cmd [[
  --       let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
  --       " In case colorscheme changes?
  --       augroup qs_colors
  --         autocmd!
  --         autocmd ColorScheme * highlight QuickScopePrimary guifg='#afff5f' gui=underline ctermfg=155 cterm=underline
  --         autocmd ColorScheme * highlight QuickScopeSecondary guifg='#5fffff' gui=underline ctermfg=81 cterm=underline
  --       augroup END
  --       " autocmd ColorScheme * highlight QuickScopePrimary guifg='#afff5f' gui=underline ctermfg=155 cterm=underline
  --       " autocmd ColorScheme * highlight QuickScopeSecondary guifg='#5fffff' gui=underline ctermfg=81 cterm=underline
  --     ]]
  --   end,
  -- },
  {
    'jinh0/eyeliner.nvim',
    config = function()
      require('eyeliner').setup {
        highlight_on_key = true,
        dim = true,
      }

      local function set_eyeliner_highlights()
        local normal_bg = vim.api.nvim_get_hl(0, { name = 'Normal' }).bg
        local dimmed_fg = vim.api.nvim_get_hl(0, { name = 'Comment' }).fg
        local primary_fg = vim.api.nvim_get_hl(0, { name = 'Constant' }).fg
        local secondary_fg = vim.api.nvim_get_hl(0, { name = 'Define' }).fg

        vim.api.nvim_set_hl(0, 'EyelinerDimmed', { fg = dimmed_fg, bg = normal_bg })
        vim.api.nvim_set_hl(0, 'EyelinerPrimary', { fg = primary_fg, bg = normal_bg, bold = true, underline = true })
        vim.api.nvim_set_hl(0, 'EyelinerSecondary', { fg = '#8dff6c', bg = normal_bg, underline = true })
      end
      -- React to colorscheme changes
      set_eyeliner_highlights()
      vim.api.nvim_create_autocmd('ColorScheme', {
        callback = set_eyeliner_highlights,
      })

      -- Fix: clear eyeliner highlights when entering insert mode (e.g. after ct_, cf_, etc.)
      local eyeliner_ns = vim.api.nvim_create_namespace 'eyeliner'
      vim.api.nvim_create_autocmd('ModeChanged', {
        pattern = '*:i', -- any mode → insert mode
        callback = function()
          vim.api.nvim_buf_clear_namespace(0, eyeliner_ns, 0, -1)
        end,
      })
    end,
  },
}
