return {
  {
    'hrsh7th/nvim-cmp',
    enabled = true,

    -- Load cmp before entering Insert mode so its source plugins
    -- can safely call cmp.register_source().
    event = 'InsertEnter',

    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          if vim.fn.has('win32') == 1
            or vim.fn.executable('make') == 0
          then
            return
          end

          return 'make install_jsregexp'
        end)(),
      },

      {
        'saadparwaiz1/cmp_luasnip',
        dependencies = {
          'hrsh7th/nvim-cmp',
        },
      },

      {
        'hrsh7th/cmp-nvim-lsp',
        dependencies = {
          'hrsh7th/nvim-cmp',
        },
      },

      {
        'hrsh7th/cmp-path',
        dependencies = {
          'hrsh7th/nvim-cmp',
        },
      },

      'rafamadriz/friendly-snippets',
    },

    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')

      require('luasnip.loaders.from_vscode').lazy_load()
      luasnip.config.setup({})

      -- Register custom PowerShell completion source.
      local powershell_completion_config_file =
        'custom.completion.powershell'

      local ps_source =
        require(powershell_completion_config_file)

      cmp.register_source(
        'ps_functions',
        ps_source.new()
      )

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        completion = {
          completeopt = 'menu,menuone,noinsert',
        },

        formatting = {
          format = function(entry, vim_item)
            local source_labels = {
              nvim_lsp = '[LSP]',
              ps_functions = '[PS]',
              copilot = '[AI]',
              luasnip = '[Snip]',
              path = '[Path]',
            }

            require(
              powershell_completion_config_file
            ).format(
              entry,
              vim_item
            )

            vim_item.menu =
              source_labels[entry.source.name]
              or entry.source.name

            return vim_item
          end,
        },

        mapping = cmp.mapping.preset.insert({
          ['<C-n>'] =
            cmp.mapping.select_next_item(),

          ['<C-p>'] =
            cmp.mapping.select_prev_item(),

          ['<C-y>'] =
            cmp.mapping.confirm({
              select = true,
            }),

          ['<C-Space>'] =
            cmp.mapping.complete({}),

          ['<C-K>'] =
            cmp.mapping.scroll_docs(-4),

          ['<C-J>'] =
            cmp.mapping.scroll_docs(4),

          ['<C-L>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),

          ['<C-H>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),
        }),

        sources = {
          {
            name = 'copilot',
          },

          {
            name = 'nvim_lsp',
          },

          {
            name = 'ps_functions',
          },

          {
            name = 'luasnip',
          },

          {
            name = 'path',
          },
        },
      })
    end,
  },
}

