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
          require('treesitter-context').setup({
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
          })

          vim.keymap.set('n', '<leader>cu', function()
            require('treesitter-context').go_to_context(vim.v.count1)
          end, { desc = '[c]ontext [u]p' })
        end,
      },
      {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main',
        init = function()
          -- Disable entire built-in ftplugin mappings to avoid conflicts.
          -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
          vim.g.no_plugin_maps = true

          -- Or, disable per filetype (add as you like)
          -- vim.g.no_python_maps = true
          -- vim.g.no_ruby_maps = true
          -- vim.g.no_rust_maps = true
          -- vim.g.no_go_maps = true
        end,
        config = function()
          -- put your config here
        end,
      },
    },
  },
}
