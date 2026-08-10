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
      --- Determine which function (if any) is being called at the cursor.
      --- Walks backwards from the cursor through the current line (and
      --- preceding continuation lines) to find the first bare command word,
      --- respecting pipes and semicolons as command boundaries.
      ps_source._calling_function = function()
        local row = vim.api.nvim_win_get_cursor(0)[1] -- 1-based
        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ''
        local col = vim.api.nvim_win_get_cursor(0)[2] -- 0-based byte offset
        -- Only look at text up to the cursor
        local before = line:sub(1, col)
        -- If the line is a continuation (backtick at end of prev line), prepend it
        while row > 1 do
          local prev = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, false)[1] or ''
          if prev:match('`%s*$') then
            before = prev:gsub('`%s*$', ' ') .. before
            row = row - 1
          else
            break
          end
        end
        -- Take the last command segment (after the last pipe or semicolon)
        local segment = before:match('[|;]%s*(.-)$') or before
        -- The first word in the segment is the command name
        local cmd = segment:match('^%s*([%w%-_]+)')
        return cmd
      end

      ps_source.complete = function(self, params, callback)
        local current_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p')
        -- Find project root (.git), fall back to current file's directory
        local root = vim.fs.root(0, '.git') or vim.fn.fnamemodify(current_file, ':h')
        local items = {}
        -- Map of lowercase function name -> list of parameter items.
        -- Populated during file scanning, then filtered by calling context.
        local func_params = {}
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
              local current_func = nil -- tracks the function whose param() block we're inside
              for i, line in ipairs(lines) do
                -- Match function declarations (before param tracking so
                -- the function line itself isn't considered "inside" its own param block)
                local func_name = line:match('^%s*[Ff]unction%s+([%w%-_]+)')
                if func_name then
                  current_func = func_name
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

                -- Track param() blocks to associate parameters with their function
                if line:match('[Pp]aram%s*%(') then
                  in_param_block = true
                  paren_depth = 0
                end
                if in_param_block then
                  for ch in line:gmatch('.') do
                    if ch == '(' then
                      paren_depth = paren_depth + 1
                    elseif ch == ')' then
                      paren_depth = paren_depth - 1
                    end
                  end

                  -- Collect parameters and associate them with current_func
                  local var_name = line:match('^%s*(%$[%w_:]+)') or line:match('^%s*%[[%w%.%[%]]+%]%s*(%$[%w_:]+)')
                  if var_name and current_func then
                    local key = current_func:lower()
                    if not func_params[key] then
                      func_params[key] = {}
                    end
                    local param_label = '-' .. var_name:gsub('^%$', '')
                    table.insert(func_params[key], {
                      label = param_label,
                      kind = require('cmp.types').lsp.CompletionItemKind.Field,
                      detail = 'param ' .. filename .. ':' .. i,
                      documentation = {
                        kind = 'markdown',
                        value = '**' .. param_label .. '**\n\nParameter of `' .. current_func .. '`\nDefined in `' .. filename .. '` (line ' .. i .. ')',
                      },
                    })
                  end

                  if paren_depth <= 0 then
                    in_param_block = false
                  end
                end

                -- Match script/module-scoped variables (skip anything inside a param block)
                if not in_param_block then
                  local var_name = line:match('^%s*(%$[%w_:]+)%s*=') or line:match('^%s*%[[%w%.%[%]]+%]%s*(%$[%w_:]+)')
                  if var_name and not seen_vars[var_name] then
                    seen_vars[var_name] = true
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

        -- Only include parameters for the function currently being called
        local calling = self._calling_function()
        if calling then
          local key = calling:lower()
          if func_params[key] then
            vim.list_extend(items, func_params[key])
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
