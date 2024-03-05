return {
  {
    'unblevable/quick-scope',
    -- Quickscope only highlight when f search
    vim.cmd [[
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
autocmd ColorScheme * highlight QuickScopePrimary guifg='#afff5f' gui=underline ctermfg=155 cterm=underline
autocmd ColorScheme * highlight QuickScopeSecondary guifg='#5fffff' gui=underline ctermfg=81 cterm=underline
]],
  },
}
