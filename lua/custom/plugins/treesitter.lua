return {

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    enabled = true,
    build = ':TSUpdate',

    config = function()
      -- [[ Configure Treesitter ]] See `:help nvim-treesitter`

      ---@diagnostic disable-next-line: missing-fields
      require('nvim-treesitter.configs').setup {
        ensure_installed = { 'powershell', 'bash', 'python', 'c', 'html', 'lua', 'markdown', 'yaml', 'vim', 'vimdoc' },
        -- Additional to ensure installed: 'c', 'rust'
        -- Autoinstall languages that are not installed
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      }

      -- There are additional nvim-treesitter modules that you can use to interact
      -- with nvim-treesitter. You should go explore a few and see what interests you:
      --
      --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
      --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
      --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
      -- NOTE: Adding powershell context awareness here for treesitter-context:
      vim.treesitter.query.set(
        'powershell',
        'context',
        [[
  (function_statement
    (script_block) @context.end) @context

  (if_statement
    (statement_block) @context.end) @context

  (elseif_clause
    (statement_block) @context.end) @context

  (else_clause
    (statement_block) @context.end) @context

  (foreach_statement
    (statement_block) @context.end) @context

  (for_statement
    (statement_block) @context.end) @context

  (while_statement
    (statement_block) @context.end) @context

  (do_statement) @context

  (try_statement
    (statement_block) @context.end) @context

  (catch_clause
    (statement_block) @context.end) @context

  (finally_clause
    (statement_block) @context.end) @context

  (class_statement
    (simple_name) @context.final) @context

  (class_method_definition
    (script_block) @context.end) @context
]]
      )
      -- NOTE: Add default filetype to 'txt' for codeblock fences in markdown files when no language is specified.
      -- Related to FeMaco plugin
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'markdown',
        once = true,
        callback = function()
          vim.treesitter.query.set(
            'markdown',
            'injections',
            [[
(fenced_code_block
  (info_string
    (language) @injection.language)
  (code_fence_content) @injection.content)

(fenced_code_block
  (fenced_code_block_delimiter)
  (block_continuation)
  (code_fence_content) @injection.content
  (#set! injection.language "text"))
      ]]
          )
        end,
      })
    end,
    dependencies = {
      {
        'nvim-treesitter/nvim-treesitter-context',
        config = function()
          -- require('treesitter-context').setup {
          --   enabled = true, -- Enable this plugin (Can be enabled/enabled later via commands)
          --   max_lines = 10, -- How many lines the window should span. Values <= 0 mean no limit.
          --   min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
          --   line_numbers = true,
          --   multiline_threshold = 20, -- Maximum number of lines to show for a single context
          --   trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
          --   mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
          --   -- Separator between context and content. Should be a single character string, like '-'.
          --   -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
          --   separator = nil,
          --   zindex = 20, -- The Z-index of the context window
          --   on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
          -- }
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
            -- Specify which node types count as "context" per language
            context = {
              default = {
                'class',
                'function',
                'method',
                'for',
                'while',
                'if',
                'switch',
                'case',
              },
              powershell = {
                'function_statement',
                'if_statement',
                'switch_statement',
                'foreach_statement',
                'for_statement',
                'while_statement',
                'do_statement',
                'try_statement',
                'trap_statement',
                'class_statement',
              },
            },
          }
        end,
      },
    },
  },
  -- Show Context at the top of the screen
}
