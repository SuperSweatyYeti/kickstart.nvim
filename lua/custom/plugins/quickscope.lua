return {

  {
    'unblevable/quick-scope',
    -- Quickscope only highlight when f search
    init = function()
      vim.cmd [[
        let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
        " In case colorscheme changes?
        augroup qs_colors
          autocmd!
          autocmd ColorScheme * highlight QuickScopePrimary guifg='#afff5f' gui=underline ctermfg=155 cterm=underline
          autocmd ColorScheme * highlight QuickScopeSecondary guifg='#5fffff' gui=underline ctermfg=81 cterm=underline
        augroup END
        " autocmd ColorScheme * highlight QuickScopePrimary guifg='#afff5f' gui=underline ctermfg=155 cterm=underline
        " autocmd ColorScheme * highlight QuickScopeSecondary guifg='#5fffff' gui=underline ctermfg=81 cterm=underline
      ]]
    end,
  },
}
