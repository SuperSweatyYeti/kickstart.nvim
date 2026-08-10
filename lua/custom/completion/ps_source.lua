-- Custom nvim-cmp source for PowerShell
--
-- Parses function names, parameters, and variable declarations from
-- .ps1/.psm1 files across the project. Bridges the gap where PSES "go to
-- definition" can find cross-file symbols but its completion engine cannot.
--
-- Parameters are scoped to the function being called at the cursor so you
-- only see relevant suggestions (e.g. typing `Get-Stuff -` only offers
-- Get-Stuff's parameters, not every parameter in the project).

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

--- Format a completion item from this source or from PSES (nvim_lsp).
--- Call this from the cmp formatting.format function.
--- Returns true if formatting was applied, false otherwise.
ps_source.format = function(entry, vim_item)
  local ft = vim.bo.filetype
  if ft ~= 'ps1' and ft ~= 'powershell' then
    return false
  end

  -- PSES returns cmdlet parameters as "Variable" (kind=6) because in
  -- PowerShell parameters are variables. Override the display for LSP
  -- items that look like parameters (no $ prefix).
  if entry.source.name == 'nvim_lsp' then
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
    return true
  end

  -- Relabel our custom source parameters from "Field" to "Param"
  if entry.source.name == 'ps_functions' then
    local detail = entry:get_completion_item().detail or ''
    if detail:match('^param ') then
      vim_item.kind = 'Param'
    end
    return true
  end

  return false
end

return ps_source
