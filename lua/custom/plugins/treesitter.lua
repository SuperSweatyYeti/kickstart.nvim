-- return {
--   { -- Highlight, edit, and navigate code
--     'nvim-treesitter/nvim-treesitter',
--     branch = 'main',
--     enabled = true,
--     lazy = false, -- important: the new version does NOT support lazy-loading
--     build = ':TSUpdate',
--
--     config = function()
--       -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
--
--       -- Setup only accepts install_dir now (optional, defaults are fine)
--       -- require('nvim-treesitter').setup { install_dir = vim.fn.stdpath('data') .. '/site' }
--
--       -- Install parsers (replaces ensure_installed)
--       -- This is async by default; use :wait() if you need synchronous install
--       require('nvim-treesitter').install {
--         'powershell', 'bash', 'python', 'c', 'html', 'lua',
--         'markdown', 'yaml', 'vim', 'vimdoc',
--       }
--
--       -- Enable highlighting and indentation per filetype (replaces highlight/indent enable)
--       vim.api.nvim_create_autocmd('FileType', {
--         pattern = {
--           'powershell', 'bash', 'python', 'c', 'html', 'lua',
--           'markdown', 'yaml', 'vim', 'vimdoc',
--         },
--         callback = function()
--           vim.treesitter.start()           -- highlighting (replaces highlight = { enable = true })
--           vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" -- indentation (replaces indent = { enable = true })
--         end,
--       })
--
--       -- NOTE: Adding powershell context awareness for treesitter-contextThis is a **complete rewrite** of `nvim-treesitter` (the `main` branch). Here's a summary of what broke and the updated config:
-- ## What Changed
--
-- 1. **`require('nvim-treesitter.configsThis is a **major rewrite** of nvim-treesitter. Here's what changed and the updated config:
--
-- ## What broke
--
-- The `main` branch is a **complete, incompatible rewrite**. The key changes are:
--
-- 1. **`require('nvim-treesitter.configs').setup { ... }` no longer exists.** The old module-based setup with `ensure_installed`, `auto_install`, `highlight = { enable = true }`, `indent = { enable = true }` is completely gone.
-- 2. **`require('nvim-treesitter.install').compilers` is gone.** The new version uses `tree-sitter-cli` to build parsers (not a raw C compiler you pick). You need [`tree-sitter-cli`](https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md) ≥ 0.26.1 installed via your system package manager.
-- 3. **`setup()` now only accepts `{ install_dir = "..." }`.** That's the only config option.
-- 4. **Parser installation is a separate explicit call:** `require('nvim-treesitter').install { ... }`
-- 5. **Highlighting and indentation are no longer enabled by the plugin.** You must enable them yourself via `vim.treesitter.start()` and `vim.bo.indentexpr` in a `FileType` autocommand.
-- 6. **Requires Neovim 0.12.0+ (nightly).**
--
-- ## Updated config
--
-- Using `config = function()` with lazy.nvim is **still valid** — it's a lazy.nvim feature, not an nvim-treesitter feature. What needs to change is the *content* inside `config`.
return {

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    enabled = true,
    lazy = false, -- nvim-treesitter does NOT support lazy-loading
    build = ':TSUpdate',

    config = function()
      -- [[ Configure Treesitter ]] See `:help nvim-treesitter`

      -- Setup only accepts install_dir (optional, defaults to stdpath('data')/site)
      -- You do NOT need to call setup if you're fine with the default.
      -- require('nvim-treesitter').setup {
      --   install_dir = vim.fn.stdpath('data') .. '/site',
      -- }

      -- Define languages once, reuse everywhere, USUALLY the same for filetype patterns
      local languages = {
        'powershell',
        'bash',
        'python',
        'c',
        'html',
        'lua',
        'markdown',
        'yaml',
        'vim',
        'vimdoc',
      }
      -- FileType patterns may include extra entries (e.g., 'sh' maps to the 'bash' parser)
      local ft_patterns = vim.list_extend(vim.list_extend({}, languages), { 'sh' })

      -- Install parsers (async by default; use :wait() for synchronous)
      require('nvim-treesitter').install(languages)

      -- Enable highlighting, indentation, and folds for all your languages
      -- (replaces the old `highlight = { enable = true }` and `indent = { enable = true }`)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = ft_patterns,
        callback = function()
          vim.treesitter.start() -- highlighting
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" -- indentation
          -- Optional: treesitter-based folds
          -- vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          -- vim.wo[0][0].foldmethod = 'expr'
        end,
      })

      -- NOTE: If you want auto-install-like behavior for ANY filetype:
      --
      -- vim.api.nvim_create_autocmd('FileType', {
      --   callback = function(ev)
      --     local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
      --     pcall(function()
      --       require('nvim-treesitter').install { lang }
      --       vim.treesitter.start()
      --     end)
      --   end,
      -- })

      -- Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
      -- Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context

      -- NOTE: Adding powershell context awareness here for treesitter-context:
      -- Add them here ~/.config/nvim/queries/language

      -- NOTE: Add codeblock fences in markdown files to treesitter-context
      -- Add them here ~/.config/nvim/queries/markdown/context.scm
      --
    end,

    dependencies = {
      {
        'nvim-treesitter/nvim-treesitter-context',
        config = function()
          require('treesitter-context').setup {
            enabled = true,
            max_lines = 10,
            min_window_height = 0,
            line_numbers = true,
            multiline_threshold = 20,
            trim_scope = 'outer',
            mode = 'cursor',
            separator = nil,
            zindex = 20,
            on_attach = nil,
          }
        end,
      },
    },
  },
}
