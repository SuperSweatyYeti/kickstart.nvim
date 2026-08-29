-- Custom nvim-cmp source for PowerShell
--
-- Provides project-local PowerShell functions, parameters and variables.
--
-- PSES sometimes returns built-in PowerShell parameters such as:
--
--     Year
--     Month
--     Day
--     Verbose
--     ErrorAction
--
-- as LSP Variable completion items.
--
-- In PowerShell:
--
--     Get-Date -Year
--
-- is a parameter, while:
--
--     $Year
--
-- is a variable.
--
-- This source:
--   * discovers sibling and imported PowerShell files
--   * parses project-local functions, parameters and variables
--   * handles Windows/Linux paths consistently
--   * parses the current buffer instead of the stale on-disk file
--   * avoids stale completion caches
--   * displays PSES variables as parameters when completing after "-"
--
-- NOTE:
-- Formatting can change how a completion is DISPLAYED, but it cannot
-- reliably change the insertion text of an item owned by nvim-lsp.
-- PSES insertion-text rewriting therefore needs to be handled separately
-- if PSES actually sends "$Year" as its insertion text.

local ps_source = {}

-- ---------------------------------------------------------------------------
-- Path helpers
-- ---------------------------------------------------------------------------

local is_windows = is_os_windows()

local function normalise_path(path)
  if not path or path == '' then
    return path
  end

  -- vim.fs.normalize is available on modern Neovim and handles both
  -- separators and "." / ".." components.
  if vim.fs and vim.fs.normalize then
    return vim.fs.normalize(path)
  end

  if is_windows then
    return path:gsub('/', '\\')
  end

  return path:gsub('\\', '/')
end

local function absolute_path(path, base)
  if not path or path == '' then
    return nil
  end

  path = normalise_path(path)

  -- Windows drive path.
  if is_windows and path:match('^%a:[\\/]') then
    return normalise_path(path)
  end

  -- POSIX absolute path.
  if path:sub(1, 1) == '/' then
    return normalise_path(path)
  end

  if base and base ~= '' then
    return normalise_path(
      vim.fn.fnamemodify(
        base .. '/' .. path,
        ':p'
      )
    )
  end

  return normalise_path(
    vim.fn.fnamemodify(path, ':p')
  )
end

-- ---------------------------------------------------------------------------
-- Cache
-- ---------------------------------------------------------------------------

local cache = {
  items = nil,
  func_params = nil,
  file_set = nil,
  timestamp = 0,
}

local CACHE_TTL = 2

local function invalidate_cache()
  cache.items = nil
  cache.func_params = nil
  cache.file_set = nil
  cache.timestamp = 0
end

ps_source._invalidate_cache = invalidate_cache

vim.api.nvim_create_autocmd(
  {
    'BufWritePost',
    'BufEnter',
    'BufFilePost',
  },
  {
    pattern = { '*.ps1', '*.psm1' },
    callback = function()
      invalidate_cache()
    end,
    desc = 'Invalidate PowerShell completion cache',
  }
)

ps_source.new = function()
  return setmetatable({}, { __index = ps_source })
end

ps_source.get_trigger_characters = function()
  return { '-', '$' }
end

ps_source.is_available = function()
  local ft = vim.bo.filetype

  return ft == 'ps1'
    or ft == 'psm1'
    or ft == 'powershell'
end

-- ---------------------------------------------------------------------------
-- Current buffer helpers
-- ---------------------------------------------------------------------------

local function get_current_line()
  local cursor = vim.api.nvim_win_get_cursor(0)

  return vim.api.nvim_buf_get_lines(
    0,
    cursor[1] - 1,
    cursor[1],
    false
  )[1] or ''
end

local function get_before_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = get_current_line()

  -- nvim_win_get_cursor() uses a zero-based byte column.
  return line:sub(1, cursor[2])
end

-- ---------------------------------------------------------------------------
-- PowerShell completion context
-- ---------------------------------------------------------------------------

--- Return true when the cursor is currently completing a PowerShell
--- parameter.
---
--- Examples:
---
---     Get-Date -
---     Get-Date -Y
---     Get-Date -Ye
---
--- return true.
---
--- But:
---
---     $Y
---     $Year
---     $obj.Y
---
--- return false.

local function is_parameter_context()
  local before_cursor = get_before_cursor()

  -- A PowerShell parameter starts with "-" and continues until whitespace
  -- or another token boundary.
  --
  -- This deliberately does NOT require the completion label itself to
  -- contain "-". PSES may report "Year" as a Variable.
  return before_cursor:match('-%a[%w_-]*$') ~= nil
    or before_cursor:match('-%w*$') ~= nil
end

--- Return the current PowerShell parameter prefix.
---
---     Get-Date -Y
---
--- returns "-Y".

local function get_parameter_prefix()
  local before_cursor = get_before_cursor()

  return before_cursor:match('-%w*$')
end

-- ---------------------------------------------------------------------------
-- Determine current command
-- ---------------------------------------------------------------------------

ps_source._calling_function = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]

  local line =
    vim.api.nvim_buf_get_lines(
      0,
      row - 1,
      row,
      false
    )[1] or ''

  local before = line:sub(1, col)

  -- Handle PowerShell continuation using the backtick.
  while row > 1 do
    local previous =
      vim.api.nvim_buf_get_lines(
        0,
        row - 2,
        row - 1,
        false
      )[1] or ''

    if previous:match('`%s*$') then
      before =
        previous:gsub('`%s*$', ' ')
        .. before

      row = row - 1
    else
      break
    end
  end

  -- Only consider the command after the most recent pipeline or
  -- statement separator.
  local segment =
    before:match('[|;]%s*(.-)$')
    or before

  -- Remove common PowerShell invocation syntax.
  segment =
    segment:gsub('^%s*&%s*', '')
  segment =
    segment:gsub('^%s*%.%s+', '')

  return segment:match(
    '^%s*([%w%-_]+)'
  )
end

-- ---------------------------------------------------------------------------
-- Import parsing
-- ---------------------------------------------------------------------------

local function extract_path(s)
  if not s then
    return nil
  end

  s = vim.trim(s)

  local path

  -- Quoted path.
  path =
    s:match(
      '^"([^"]+%.psm?1)"'
    )

  if not path then
    path =
      s:match(
        "^'([^']+%.psm?1)'"
      )
  end

  -- Unquoted path.
  if not path then
    path =
      s:match(
        '^(%S+%.psm?1)'
      )
  end

  if not path then
    return nil
  end

  return path
end

local function parse_import(line)
  -- Strip comments while preserving quoted strings reasonably well.
  local code =
    line:match('^(.-)%s*#')
    or line

  code = vim.trim(code)

  -- Dot source:
  --
  --     . ./foo.ps1
  --     . "$PSScriptRoot/foo.ps1"
  local after =
    code:match(
      '^%.%s+(.+)'
    )

  if after then
    local ref = extract_path(after)

    if ref then
      return ref
    end
  end

  -- Import-Module:
  --
  --     Import-Module ./foo.psm1
  --     Import-Module -Name ./foo.psm1
  --     import-module "$PSScriptRoot/foo.psm1"
  after =
    code:match(
      '^[Ii]mport%-[Mm]odule%s+(.+)'
    )

  if after then
    local after_name =
      after:match(
        '^%-[Nn]ame%s+(.+)'
      )

    local ref =
      extract_path(
        after_name or after
      )

    if ref then
      return ref
    end
  end

  -- using module:
  --
  --     using module ./foo.psm1
  after =
    code:match(
      '^[Uu]sing%s+[Mm]odule%s+(.+)'
    )

  if after then
    local ref =
      extract_path(after)

    if ref then
      return ref
    end
  end

  return nil
end

-- ---------------------------------------------------------------------------
-- Resolve imported path
-- ---------------------------------------------------------------------------

local function resolve_import(file, ref)
  if not ref then
    return nil
  end

  ref = vim.trim(ref)

  -- Expand the PowerShell variable that is useful for local modules.
  ref =
    ref:gsub(
      '^%$PSScriptRoot[\\/]',
      ''
    )

  local file_dir =
    vim.fn.fnamemodify(
      file,
      ':h'
    )

  -- Absolute path.
  if ref:sub(1, 1) == '/'
    or (
      is_windows
      and ref:match('^%a:[\\/]')
    )
  then
    return normalise_path(ref)
  end

  return absolute_path(
    ref,
    file_dir
  )
end

-- ---------------------------------------------------------------------------
-- File discovery
-- ---------------------------------------------------------------------------

local function collect_files(current_file)
  current_file =
    normalise_path(current_file)

  local current_dir =
    vim.fn.fnamemodify(
      current_file,
      ':h'
    )

  local seen = {
    [current_file] = true,
  }

  local result = {}

  -- Sibling files.
  local siblings =
    vim.fn.glob(
      current_dir .. '/*.ps1',
      false,
      true
    )

  vim.list_extend(
    siblings,
    vim.fn.glob(
      current_dir .. '/*.psm1',
      false,
      true
    )
  )

  for _, file in ipairs(siblings) do
    local full =
      normalise_path(
        vim.fn.fnamemodify(
          file,
          ':p'
        )
      )

    if not seen[full] then
      seen[full] = true
      table.insert(result, full)
    end
  end

  -- Imported files.
  local queue = {
    current_file,
  }

  local queue_index = 1

  while queue_index <= #queue do
    local file = queue[queue_index]
    queue_index = queue_index + 1

    local lines

    if file == current_file then
      -- IMPORTANT:
      -- Parse the current buffer, not the saved file on disk.
      lines =
        vim.api.nvim_buf_get_lines(
          0,
          0,
          -1,
          false
        )
    else
      local ok

      ok, lines =
        pcall(
          vim.fn.readfile,
          file
        )

      if not ok then
        lines = nil
      end
    end

    if lines then
      for _, line in ipairs(lines) do
        local ref =
          parse_import(line)

        if ref then
          local full =
            resolve_import(
              file,
              ref
            )

          if full then
            full =
              normalise_path(full)

            if not seen[full]
              and vim.fn.filereadable(full) == 1
            then
              seen[full] = true

              table.insert(
                result,
                full
              )

              table.insert(
                queue,
                full
              )
            end
          end
        end
      end
    end
  end

  return result
end

-- ---------------------------------------------------------------------------
-- Parse PowerShell files
-- ---------------------------------------------------------------------------

local function get_file_lines(
  file,
  current_file
)
  if file == current_file then
    return vim.api.nvim_buf_get_lines(
      0,
      0,
      -1,
      false
    )
  end

  local ok, lines =
    pcall(
      vim.fn.readfile,
      file
    )

  if not ok then
    return nil
  end

  return lines
end

local function parse_file(
  file,
  current_file,
  items,
  func_params
)
  local lines =
    get_file_lines(
      file,
      current_file
    )

  if not lines then
    return
  end

  local filename =
    vim.fn.fnamemodify(
      file,
      ':t'
    )

  local seen_vars = {}
  local seen_params = {}

  local in_param_block = false
  local paren_depth = 0

  local current_func = nil
  local function_brace_depth = 0

  local CompletionItemKind =
    require('cmp.types').lsp.CompletionItemKind

  for i, line in ipairs(lines) do

    -- ---------------------------------------------------------------
    -- Function declaration
    -- ---------------------------------------------------------------

    local func_name =
      line:match(
        '^%s*[Ff]unction%s+([%w%-_]+)'
      )

    if func_name then
      current_func = func_name
      function_brace_depth = 0

      table.insert(
        items,
        {
          label = func_name,

          kind =
            CompletionItemKind.Function,

          detail =
            filename
            .. ':'
            .. i,

          documentation = {
            kind = 'markdown',

            value =
              '**'
              .. func_name
              .. '**\n\nDefined in `'
              .. filename
              .. '` (line '
              .. i
              .. ')',
          },
        }
      )
    end

    -- ---------------------------------------------------------------
    -- Track function braces.
    -- ---------------------------------------------------------------

    if current_func then
      for ch in line:gmatch('.') do
        if ch == '{' then
          function_brace_depth =
            function_brace_depth + 1
        elseif ch == '}' then
          function_brace_depth =
            function_brace_depth - 1
        end
      end

      if function_brace_depth < 0 then
        current_func = nil
        function_brace_depth = 0
      end
    end

    -- ---------------------------------------------------------------
    -- Param block
    -- ---------------------------------------------------------------

    if line:match(
      '[Pp]aram%s*%('
    ) then
      in_param_block = true
      paren_depth = 0
    end

    if in_param_block then
      for ch in line:gmatch('.') do
        if ch == '(' then
          paren_depth =
            paren_depth + 1
        elseif ch == ')' then
          paren_depth =
            paren_depth - 1
        end
      end

      local var_name =
        line:match(
          '^%s*(%$[%w_:]+)'
        )
        or line:match(
          '^%s*%[[%w%.%[%]]+%]%s*(%$[%w_:]+)'
        )

      if var_name
        and current_func
      then
        local key =
          current_func:lower()

        if not func_params[key] then
          func_params[key] = {}
        end

        if not seen_params[var_name] then
          seen_params[var_name] = true

          local param_label =
            '-'
            .. var_name:gsub(
              '^%$',
              ''
            )

          table.insert(
            func_params[key],
            {
              label = param_label,

              kind =
                CompletionItemKind.Field,

              detail =
                'param '
                .. filename
                .. ':'
                .. i,

              documentation = {
                kind = 'markdown',

                value =
                  '**'
                  .. param_label
                  .. '**\n\nParameter of `'
                  .. current_func
                  .. '`\nDefined in `'
                  .. filename
                  .. '` (line '
                  .. i
                  .. ')',
              },
            }
          )
        end
      end

      if paren_depth <= 0 then
        in_param_block = false
      end
    end

    -- ---------------------------------------------------------------
    -- Variables
    -- ---------------------------------------------------------------

    if not in_param_block then
      local var_name =
        line:match(
          '^%s*(%$[%w_:]+)%s*='
        )
        or line:match(
          '^%s*%[[%w%.%[%]]+%]%s*(%$[%w_:]+)'
        )

      if var_name
        and not seen_vars[var_name]
      then
        seen_vars[var_name] = true

        table.insert(
          items,
          {
            label = var_name,

            kind =
              CompletionItemKind.Variable,

            detail =
              'var '
              .. filename
              .. ':'
              .. i,

            documentation = {
              kind = 'markdown',

              value =
                '**'
                .. var_name
                .. '**\n\nDefined in `'
                .. filename
                .. '` (line '
                .. i
                .. ')',
            },
          }
        )
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Build cache
-- ---------------------------------------------------------------------------

local function build_cache(current_file)
  local ps_files =
    collect_files(current_file)

  local sorted =
    vim.deepcopy(ps_files)

  table.sort(sorted)

  local file_set_key =
    table.concat(
      sorted,
      '|'
    )

  local items = {}
  local func_params = {}

  for _, file in ipairs(ps_files) do
    parse_file(
      file,
      current_file,
      items,
      func_params
    )
  end

  cache.items =
    vim.deepcopy(items)

  cache.func_params =
    vim.deepcopy(func_params)

  cache.file_set =
    file_set_key

  -- Use wall-clock time rather than os.clock().
  cache.timestamp =
    vim.uv.hrtime() / 1e9

  return items, func_params
end

-- ---------------------------------------------------------------------------
-- Custom completion
-- ---------------------------------------------------------------------------

ps_source.complete = function(
  self,
  params,
  callback
)
  local current_file =
    vim.fn.fnamemodify(
      vim.api.nvim_buf_get_name(0),
      ':p'
    )

  current_file =
    normalise_path(current_file)

  if current_file == '' then
    callback({
      items = {},
    })

    return
  end

  local ps_files =
    collect_files(current_file)

  local sorted =
    vim.deepcopy(ps_files)

  table.sort(sorted)

  local file_set_key =
    table.concat(
      sorted,
      '|'
    )

  local now =
    vim.uv.hrtime() / 1e9

  local items
  local func_params

  if cache.file_set == file_set_key
    and cache.items
    and cache.func_params
    and (now - cache.timestamp) < CACHE_TTL
  then
    items =
      vim.deepcopy(
        cache.items
      )

    func_params =
      vim.deepcopy(
        cache.func_params
      )
  else
    items, func_params =
      build_cache(current_file)
  end

  local calling =
    self._calling_function()

  if calling then
    local key =
      calling:lower()

    if func_params[key] then
      vim.list_extend(
        items,
        vim.deepcopy(
          func_params[key]
        )
      )
    end
  end

  callback({
    items = items,
  })
end

-- ---------------------------------------------------------------------------
-- Formatting
-- ---------------------------------------------------------------------------

ps_source.format = function(
  entry,
  vim_item
)
  local ft = vim.bo.filetype

  if ft ~= 'ps1'
    and ft ~= 'psm1'
    and ft ~= 'powershell'
  then
    return false
  end

  -- ---------------------------------------------------------------
  -- Our project-local source.
  -- ---------------------------------------------------------------

  if entry.source.name == 'ps_functions' then
    local item =
      entry:get_completion_item()

    local detail =
      item.detail or ''

    if detail:match('^param ') then
      vim_item.kind = 'Param'
    end

    return true
  end

  -- ---------------------------------------------------------------
  -- PSES / nvim-lsp.
  --
  -- PSES can report built-in PowerShell parameters as Variables.
  --
  -- Example:
  --
  --     Year
  --
  -- with:
  --
  --     kind = Variable
  --
  -- When completion is being requested after "-", display it as:
  --
  --     -Year
  --
  -- IMPORTANT:
  -- This changes the display only. The actual insertion text belongs
  -- to the LSP completion item.
  -- ---------------------------------------------------------------

  if entry.source.name == 'nvim_lsp' then
    local item =
      entry:get_completion_item()

    -- LSP CompletionItemKind.Variable = 6.
    if item.kind == 6
      and is_parameter_context()
    then
      vim_item.kind = 'Param'

      local abbr =
        vim_item.abbr
        or item.label
        or ''

      if not abbr:match('^%-') then
        vim_item.abbr =
          '-' .. abbr
      end
    end

    return true
  end

  return false
end

-- ---------------------------------------------------------------------------
-- Cross-file definition lookup
-- ---------------------------------------------------------------------------

--- Search all discovered project files for the definition of a
--- PowerShell function or variable.
---
--- @param symbol string  The symbol to find.  Functions are matched
---   by name (case-insensitive).  Variables must include the leading
---   "$" (e.g. "$DownloadPath").
---
--- @return table|nil  { file = string, line = number } or nil.

ps_source.find_definition = function(symbol)
  local current_file = normalise_path(
    vim.fn.fnamemodify(
      vim.api.nvim_buf_get_name(0),
      ':p'
    )
  )

  if not current_file
    or current_file == ''
  then
    return nil
  end

  -- Build the list: current file first, then siblings/imports.
  local files =
    collect_files(current_file)

  table.insert(files, 1, current_file)

  local is_var =
    symbol:sub(1, 1) == '$'

  local search_lower = symbol:lower()

  for _, file in ipairs(files) do
    local lines =
      get_file_lines(
        file,
        current_file
      )

    if lines then
      for i, line in ipairs(lines) do
        if is_var then
          -- Variable assignment.
          local var =
            line:match(
              '^%s*(%$[%w_:]+)%s*='
            )
            or line:match(
              '^%s*%[[%w%.%[%]]+%]'
              .. '%s*(%$[%w_:]+)'
            )

          if var
            and var:lower()
              == search_lower
          then
            return {
              file = file,
              line = i,
            }
          end
        else
          -- Function definition.
          local func =
            line:match(
              '^%s*[Ff]unction'
              .. '%s+([%w%-_]+)'
            )

          if func
            and func:lower()
              == search_lower
          then
            return {
              file = file,
              line = i,
            }
          end
        end
      end
    end
  end

  return nil
end

-- ---------------------------------------------------------------------------
-- Debug
-- ---------------------------------------------------------------------------

vim.api.nvim_create_user_command(
  'PSCompletionDebug',
  function()
    local current_file =
      vim.fn.fnamemodify(
        vim.api.nvim_buf_get_name(0),
        ':p'
      )

    current_file =
      normalise_path(current_file)

    local current_dir =
      vim.fn.fnamemodify(
        current_file,
        ':h'
      )

    local out = {
      '=== PS Completion Debug ===',
      'Platform: '
        .. (is_windows and 'Windows' or 'Linux/Unix'),

      'Current file: ' .. current_file,
      'Current dir:  ' .. current_dir,
      '',

      '--- Current completion context ---',

      'Before cursor: '
        .. get_before_cursor(),

      'Parameter context: '
        .. tostring(
          is_parameter_context()
        ),

      'Parameter prefix: '
        .. tostring(
          get_parameter_prefix()
        ),

      'Calling function: '
        .. tostring(
          ps_source._calling_function()
        ),

      '',

      '--- Import parsing ---',
    }

    local lines =
      vim.api.nvim_buf_get_lines(
        0,
        0,
        -1,
        false
      )

    local import_count = 0

    for i, line in ipairs(lines) do
      local ref =
        parse_import(line)

      if ref then
        import_count =
          import_count + 1

        local full =
          resolve_import(
            current_file,
            ref
          )

        local readable =
          full ~= nil
          and vim.fn.filereadable(full) == 1

        table.insert(
          out,
          string.format(
            '  L%-4d %s',
            i,
            line:sub(1, 80)
          )
        )

        table.insert(
          out,
          string.format(
            '        ref:      %s',
            ref
          )
        )

        table.insert(
          out,
          string.format(
            '        resolved: %s',
            tostring(full)
          )
        )

        table.insert(
          out,
          string.format(
            '        exists:   %s',
            tostring(readable)
          )
        )
      end
    end

    if import_count == 0 then
      table.insert(
        out,
        '  (no import lines detected)'
      )
    end

    table.insert(out, '')

    table.insert(
      out,
      '--- Discovered files ---'
    )

    local files =
      collect_files(current_file)

    if #files == 0 then
      table.insert(
        out,
        '  (none)'
      )
    end

    for _, file in ipairs(files) do
      table.insert(
        out,
        '  ' .. file
      )
    end

    table.insert(out, '')

    table.insert(
      out,
      string.format(
        'Total: %d files (excluding current)',
        #files
      )
    )

    table.insert(
      out,
      ''
    )

    table.insert(
      out,
      '--- Cache ---'
    )

    table.insert(
      out,
      'Cache populated: '
        .. tostring(
          cache.items ~= nil
        )
    )

    table.insert(
      out,
      'Cache file set: '
        .. tostring(
          cache.file_set
        )
    )

    table.insert(
      out,
      'Cache age: '
        .. string.format(
          '%.3fs',
          (vim.uv.hrtime() / 1e9)
            - cache.timestamp
        )
    )

    local buf =
      vim.api.nvim_create_buf(
        false,
        true
      )

    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      out
    )

    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].filetype = 'text'

    local width =
      math.min(
        120,
        vim.o.columns - 4
      )

    local height =
      math.min(
        #out + 1,
        vim.o.lines - 4
      )

    vim.api.nvim_open_win(
      buf,
      true,
      {
        relative = 'editor',
        width = width,
        height = height,

        row =
          math.floor(
            (vim.o.lines - height) / 2
          ),

        col =
          math.floor(
            (vim.o.columns - width) / 2
          ),

        style = 'minimal',
        border = 'rounded',
        title = ' PS Completion Debug ',
        title_pos = 'center',
      }
    )
  end,
  {
    desc =
      'Debug PowerShell completion file discovery',
  }
)

return ps_source


