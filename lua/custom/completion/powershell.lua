-- Custom nvim-cmp source for PowerShell
--
-- Parses function names, parameters, and variable declarations from
-- .ps1/.psm1 files that are actually related to the current file. Bridges
-- the gap where PSES "go to definition" can find cross-file symbols but
-- its completion engine cannot.
--
-- File discovery strategy (avoids expensive recursive globbing):
--   1. Sibling files in the same directory as the current file
--   2. Imports followed recursively:
--      - Dot-source:    . .\file.ps1   . $PSScriptRoot\file.ps1
--      - Import-Module: Import-Module .\mod.psm1   Import-Module $PSScriptRoot\mod.psm1
--      - Using module:  using module .\mod.psm1
--
-- Results are cached and invalidated on buffer write or after a timeout
-- so we don't re-read files on every keystroke.
--
-- Parameters are scoped to the function being called at the cursor so you
-- only see relevant suggestions (e.g. typing `Get-Stuff -` only offers
-- Get-Stuff's parameters, not every parameter in the project).

local ps_source = {}

-- ---------------------------------------------------------------------------
-- Cache: avoid re-scanning files on every completion request
-- ---------------------------------------------------------------------------
local cache = {
  items = nil, -- list of completion items (functions + variables)
  func_params = nil, -- map of func_name:lower() -> param items
  file_set = nil, -- stringified sorted file list used as cache key
  timestamp = 0, -- os.clock() of last scan
}
local CACHE_TTL = 10 -- seconds before a rescan is allowed

--- Invalidate the cache (called on BufWritePost via autocmd).
ps_source._invalidate_cache = function()
  cache.file_set = nil
end

-- Set up the autocmd once when the module is first loaded.
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = { '*.ps1', '*.psm1' },
  callback = function()
    ps_source._invalidate_cache()
  end,
  desc = 'Invalidate PS completion cache when a PowerShell file is saved',
})

ps_source.new = function()
  return setmetatable({}, { __index = ps_source })
end

ps_source.get_trigger_characters = function()
  return { '-', '$' }
end

ps_source.is_available = function()
  local ft = vim.bo.filetype
  return ft == 'ps1' or ft == 'psm1' or ft == 'powershell'
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

-- ---------------------------------------------------------------------------
-- Import reference parsing
-- ---------------------------------------------------------------------------

--- Try to extract a file path reference from a single line of PowerShell.
--- Returns nil if the line doesn't contain a recognised import pattern.
---
--- Recognised patterns (case-insensitive):
---   . .\path.ps1              . ./path.ps1
---   . $PSScriptRoot\path      . "$PSScriptRoot/path"
---   Import-Module .\path      Import-Module $PSScriptRoot\path
---   Import-Module -Name .\p   Import-Module -Name $PSScriptRoot\p
---   using module .\path       using module $PSScriptRoot\path
local function parse_import(line)
  -- Strip inline comments so we don't follow commented-out imports
  local code = line:match('^(.-)#') or line

  -- 1. Dot-source:  . .\path  |  . $PSScriptRoot\path
  local ref = code:match('^%s*%.%s+["\']?%.[\\/](.+%.psm?1)["\']?')
    or code:match('^%s*%.%s+["\']?%$PSScriptRoot[\\/](.+%.psm?1)["\']?')
  if ref then
    return ref
  end

  -- 2. Import-Module (with optional -Name flag)
  --    Import-Module .\mod.psm1
  --    Import-Module -Name "$PSScriptRoot\mod.psm1"
  ref = code:match('^%s*[Ii]mport%-[Mm]odule%s+%-[Nn]ame%s+["\']?%.[\\/](.+%.psm?1)["\']?')
    or code:match('^%s*[Ii]mport%-[Mm]odule%s+%-[Nn]ame%s+["\']?%$PSScriptRoot[\\/](.+%.psm?1)["\']?')
    or code:match('^%s*[Ii]mport%-[Mm]odule%s+["\']?%.[\\/](.+%.psm?1)["\']?')
    or code:match('^%s*[Ii]mport%-[Mm]odule%s+["\']?%$PSScriptRoot[\\/](.+%.psm?1)["\']?')
  if ref then
    return ref
  end

  -- 3. using module .\path  |  using module $PSScriptRoot\path
  ref = code:match('^%s*[Uu]sing%s+[Mm]odule%s+["\']?%.[\\/](.+%.psm?1)["\']?')
    or code:match('^%s*[Uu]sing%s+[Mm]odule%s+["\']?%$PSScriptRoot[\\/](.+%.psm?1)["\']?')
  if ref then
    return ref
  end

  return nil
end

-- ---------------------------------------------------------------------------
-- File discovery
-- ---------------------------------------------------------------------------

--- Collect the set of files to scan for completions.
--- 1. Sibling .ps1/.psm1 files in the same directory
--- 2. Recursively follow import references from the current buffer
--- Returns a list of absolute paths (excluding current_file).
local function collect_files(current_file)
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  local seen = { [current_file] = true } -- always skip the file being edited
  local result = {}

  -- 1. Sibling files in the same directory
  local siblings = vim.fn.glob(current_dir .. '/*.ps1', false, true)
  vim.list_extend(siblings, vim.fn.glob(current_dir .. '/*.psm1', false, true))
  for _, f in ipairs(siblings) do
    local full = vim.fn.fnamemodify(f, ':p')
    if not seen[full] then
      seen[full] = true
      table.insert(result, full)
    end
  end

  -- 2. Follow import references starting from the current buffer
  local queue = { current_file }
  while #queue > 0 do
    local file = table.remove(queue, 1)
    local file_dir = vim.fn.fnamemodify(file, ':h')
    local ok, lines
    if file == current_file then
      -- Read from the live buffer so unsaved imports are picked up
      lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      ok = true
    else
      ok, lines = pcall(vim.fn.readfile, file)
    end
    if ok and lines then
      for _, line in ipairs(lines) do
        local ref = parse_import(line)
        if ref then
          -- Normalise separators
          ref = ref:gsub('/', '\\')
          local full = vim.fn.fnamemodify(file_dir .. '/' .. ref, ':p')
          if not seen[full] and vim.fn.filereadable(full) == 1 then
            seen[full] = true
            table.insert(result, full)
            table.insert(queue, full) -- recurse into this file's imports too
          end
        end
      end
    end
  end

  return result
end

-- ---------------------------------------------------------------------------
-- File parsing (symbols)
-- ---------------------------------------------------------------------------

--- Parse a single file and append its symbols to items / func_params.
local function parse_file(file, items, func_params)
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok or not lines then
    return
  end
  local filename = vim.fn.fnamemodify(file, ':t')
  local seen_vars = {}
  local in_param_block = false
  local paren_depth = 0
  local current_func = nil
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

-- ---------------------------------------------------------------------------
-- nvim-cmp complete callback
-- ---------------------------------------------------------------------------

ps_source.complete = function(self, params, callback)
  local current_file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p')

  -- Discover related files (siblings + import graph)
  local ps_files = collect_files(current_file)

  -- Build a cache key from the sorted file list
  local sorted = vim.deepcopy(ps_files)
  table.sort(sorted)
  local file_set_key = table.concat(sorted, '|')

  -- Use cached results if the file set hasn't changed and TTL hasn't expired
  local now = os.clock()
  if cache.file_set == file_set_key and (now - cache.timestamp) < CACHE_TTL then
    local items = vim.deepcopy(cache.items)
    local calling = self._calling_function()
    if calling and cache.func_params[calling:lower()] then
      vim.list_extend(items, cache.func_params[calling:lower()])
    end
    callback({ items = items })
    return
  end

  -- Scan all discovered files
  local items = {}
  local func_params = {}
  for _, file in ipairs(ps_files) do
    parse_file(file, items, func_params)
  end

  -- Update cache
  cache.items = vim.deepcopy(items)
  cache.func_params = func_params
  cache.file_set = file_set_key
  cache.timestamp = now

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
