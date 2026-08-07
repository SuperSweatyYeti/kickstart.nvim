return {
  { -- Autocompletion
    'hrsh7th/nvim-cmp',
    enabled = true,
    event = 'InsertEnter',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          -- Build Step is needed for regex support in snippets
          -- This step is not supported in many windows environments
          -- Remove the below condition to re-enable on windows
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
      },
      'saadparwaiz1/cmp_luasnip',

      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',

      -- If you want to add a bunch of pre-configured snippets,
      --    you can use this plugin to help you. It even has snippets
      --    for various frameworks/libraries/etc. but you will have to
      --    set up the ones that are useful for you.
      'rafamadriz/friendly-snippets',
    },
    config = function()
      require('luasnip.loaders.from_vscode').lazy_load()
      -- See `:help cmp`
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.config.setup {}

      -- NOTE:
      -- Custom cmp sourcing for Powershell: parses function names from .ps1/.psm1 files
      -- in the same directory. Bridges the gap where PSES gd can find
      -- cross-file functions but its completion engine cannot.
      local ps_source = {}
      ps_source.new = function()
        return setmetatable({}, { __index = ps_source })
      end
      ps_source.get_trigger_characters = function()
        return { '-' }
      end
      ps_source.is_available = function()
        local ft = vim.bo.filetype
        return ft == 'ps1' or ft == 'powershell'
      end
      ps_source.complete = function(self, params, callback)
        local current_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p')
        local dir = vim.fn.fnamemodify(current_file, ':h')
        local items = {}
        local ps_files = vim.fn.glob(dir .. '/*.ps1', false, true)
        vim.list_extend(ps_files, vim.fn.glob(dir .. '/*.psm1', false, true))
        for _, file in ipairs(ps_files) do
          if vim.fn.fnamemodify(file, ':p') ~= current_file then
            local ok, lines = pcall(vim.fn.readfile, file)
            if ok and lines then
              local filename = vim.fn.fnamemodify(file, ':t')
              for i, line in ipairs(lines) do
                local func_name = line:match('^%s*[Ff]unction%s+([%w%-_]+)')
                if func_name then
                  table.insert(items, {
                    label = func_name,
                    kind = require('cmp.types').lsp.CompletionItemKind.Function,
                    detail = filename .. ':' .. i,
                    documentation = {
                      kind = 'markdown',
                      value = '**' .. func_name .. '**\n\nDefined in `' .. filename .. '` (line ' .. i .. ')',
                    },
                  })
                end
              end
            end
          end
        end
        callback({ items = items })
      end
      cmp.register_source('ps_functions', ps_source.new())

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,noinsert' },

        -- For an understanding of why these mappings were
        -- chosen, you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        mapping = cmp.mapping.preset.insert {
          -- Select the [n]ext item
          ['<C-n>'] = cmp.mapping.select_next_item(),
          -- Select the [p]revious item
          ['<C-p>'] = cmp.mapping.select_prev_item(),

          -- Accept ([y]es) the completion.
          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ['<C-y>'] = cmp.mapping.confirm { select = true },

          -- Manually trigger a completion from nvim-cmp.
          --  Generally you don't need this, because nvim-cmp will display
          --  completions whenever it has completion options available.
          ['<C-Space>'] = cmp.mapping.complete {},

          -- Scroll through the doc preview
          ['<C-K>'] = cmp.mapping.scroll_docs(-4),
          ['<C-J>'] = cmp.mapping.scroll_docs(4),

          -- Think of <c-l> as moving to the right of your snippet expansion.
          --  So if you have a snippet that's like:
          --  function $name($args)
          --    $body
          --  end
          --
          -- <c-l> will move you to the right of each of the expansion locations.
          -- <c-h> is similar, except moving you backwards.
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
        },
        sources = {
          -- if copilot is enabled, you can use this source to get suggestions
          {
            name = 'copilot', -- Only works if you have `copilot` installed and enabled
            -- NOTE: This source will only work if you have `copilot` installed
            -- and configured properly. Otherwise, it will fallback to other sources.
            -- You can also disable this in the filetype settings below.
          },
          { name = 'nvim_lsp' },
          { name = 'ps_functions' },
          { name = 'luasnip' },
          { name = 'path' },
        },
      }
    end,
  },
}
