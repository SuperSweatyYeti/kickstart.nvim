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
          if vim.fn.has('win32') == 1 or vim.fn.executable('make') == 0 then
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
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      luasnip.config.setup({})

      -- NOTE:
      -- Custom cmp sourcing for Powershell: parses function names and variable
      -- declarations from .ps1/.psm1 files in the same directory. Bridges the
      -- gap where PSES gd can find cross-file symbols but its completion
      -- engine cannot.
      local ps_source = {}
      ps_source.new = function()
        return setmetatable({}, { __index = ps_source })
      end
      ps_source.get_trigger_characters = function()
        return { '-', '$' }
      end
      ps_source.is_available = function()
        local ft = vim.bo.filetype
        return ft == 'ps1' or ft == 'powershell'
      end
      ps_source.complete = function(self, params, callback)
        local current_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p')
        -- Find project root (.git), fall back to current file's directory
        local root = vim.fs.root(0, '.git') or vim.fn.fnamemodify(current_file, ':h')
        local items = {}
        -- Search recursively through the entire project
        local ps_files = vim.fn.glob(root .. '/**/*.ps1', false, true)
        vim.list_extend(ps_files, vim.fn.glob(root .. '/**/*.psm1', false, true))
        for _, file in ipairs(ps_files) do
          if vim.fn.fnamemodify(file, ':p') ~= current_file then
            local ok, lines = pcall(vim.fn.readfile, file)
            if ok and lines then
              local filename = vim.fn.fnamemodify(file, ':t')
              local seen_vars = {}
              local in_param_block = false
              local paren_depth = 0
              for i, line in ipairs(lines) do
                -- Track param() blocks to skip parameters (PSES already handles those)
                if line:match('[Pp]aram%s*%(') then
                  in_param_block = true
                  paren_depth = 0
                end
                if in_param_block then
                  for ch in line:gmatch('.') do
                    if ch == '(' then
                      paren_depth = paren_depth + 1
                    end
                    if ch == ')' then
                      paren_depth = paren_depth - 1
                    end
                  end
                  if paren_depth <= 0 then
                    in_param_block = false
                  end
                end

                -- Match function declarations
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

                -- Match variables and parameters
                local var_name = line:match('^%s*(%$[%w_:]+)%s*=') or line:match('^%s*%[[%w%.%[%]]+%]%s*(%$[%w_:]+)')
                if var_name and not seen_vars[var_name] then
                  seen_vars[var_name] = true
                  if in_param_block then
                    -- Parameters: suggest as -ParamName (how you actually type them)
                    local param_label = '-' .. var_name:gsub('^%$', '')
                    table.insert(items, {
                      label = param_label,
                      kind = require('cmp.types').lsp.CompletionItemKind.Field,
                      detail = 'param ' .. filename .. ':' .. i,
                      documentation = {
                        kind = 'markdown',
                        value = '**' .. param_label .. '**\n\nParameter defined in `' .. filename .. '` (line ' .. i .. ')',
                      },
                    })
                  else
                    -- Variables: suggest as $VarName
                    table.insert(items, {
                      label = var_name,
                      kind = require('cmp.types').lsp.CompletionItemKind.Variable,
                      detail = 'var ' .. filename .. ':' .. i,
                      documentation = {
                        kind = 'markdown',
                        value = '**' .. var_name .. '**\n\nDefined in `' .. filename .. '` (line ' .. i .. ')',
                      },
                    })
                  end
                end
              end
            end
          end
        end
        callback({ items = items })
      end
      cmp.register_source('ps_functions', ps_source.new())

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,noinsert' },

        -- Show source labels in completion menu so you can tell
        -- where each suggestion comes from
        formatting = {
          format = function(entry, vim_item)
            local source_labels = {
              nvim_lsp = '[LSP]',
              ps_functions = '[PS]',
              copilot = '[AI]',
              luasnip = '[Snip]',
              path = '[Path]',
            }
            -- PSES returns cmdlet parameters as "Variable" (kind=6) because in
            -- PowerShell parameters are variables. Override the display for LSP
            -- items that look like parameters (no $ prefix).
            local ft = vim.bo.filetype
            -- if (ft == 'ps1' or ft == 'powershell') and entry.source.name == 'nvim_lsp' then
            --   local raw_kind = entry:get_completion_item().kind
            --   local abbr = vim_item.abbr or ''
            --   -- kind 6 = Variable in LSP spec
            --   -- if raw_kind == 6 and not abbr:match('^%s*%$') then
            --   --   vim_item.kind = 'Param'
            --   -- end
            --   if raw_kind == 6 and abbr:match('^%s*%-[%w_]') then
            --     vim_item.kind = 'Param'
            --   end
            -- end
            if (ft == 'ps1' or ft == 'powershell') and entry.source.name == 'nvim_lsp' then
              local completion_item = entry:get_completion_item()
              local raw_kind = completion_item.kind
              local abbr = vim_item.abbr or ''

              -- kind 6 = Variable in LSP spec
              if raw_kind == 6 then
                -- Parameters are displayed with "-", variables with "$".
                if abbr:match('^%s*%-[%w_]') then
                  vim_item.kind = 'Param'
                elseif not abbr:match('^%s*%$') then
                  vim_item.abbr = '$' .. abbr
                end
              end
            end
            -- Relabel our custom source parameters from "Field" to "Param"
            if entry.source.name == 'ps_functions' then
              local detail = entry:get_completion_item().detail or ''
              if detail:match('^param ') then
                vim_item.kind = 'Param'
              end
            end
            vim_item.menu = source_labels[entry.source.name] or entry.source.name
            return vim_item
          end,
        },

        -- For an understanding of why these mappings were
        -- chosen, you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        mapping = cmp.mapping.preset.insert({
          -- Select the [n]ext item
          ['<C-n>'] = cmp.mapping.select_next_item(),
          -- Select the [p]revious item
          ['<C-p>'] = cmp.mapping.select_prev_item(),

          -- Accept ([y]es) the completion.
          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ['<C-y>'] = cmp.mapping.confirm({ select = true }),

          -- Manually trigger a completion from nvim-cmp.
          --  Generally you don't need this, because nvim-cmp will display
          --  completions whenever it has completion options available.
          ['<C-Space>'] = cmp.mapping.complete({}),

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
        }),
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
      })
    end,
  },
}
