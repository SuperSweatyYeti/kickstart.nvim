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
-- PSES can return the former as a Variable completion with "$Year"
-- as the insertion text. This source fixes the insertion text and
-- displays the item as Param when completion is being requested after "-".

local ps_source = {}

-- ---------------------------------------------------------------------------
-- Path helpers
-- ---------------------------------------------------------------------------

local is_windows =
  is_os_windows and is_os_windows()
  or vim.fn.has('win32') == 1

local sep = is_windows and '\\' or '/'

local function normalise_path(p)
  if is_windows then
    return p:gsub('/', '\\')
  end

  return p:gsub('\\', '/')
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

local CACHE_TTL = 10

ps_source._invalidate_cache = function()
  cache.file_set = nil
end

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

  return ft == 'ps1'
    or ft == 'psm1'
    or ft == 'powershell'
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
  local cursor = vim.api.nvim_win_get_cursor(0)

  local line =
    vim.api.nvim_buf_get_lines(
      0,
      cursor[1] - 1,
      cursor[1],
      false
    )[1] or ''

  local before_cursor =
    line:sub(1, cursor[2])

  return before_cursor:match('-%w*$') ~= nil
end

--- Return the current PowerShell parameter prefix.
---
---     Get-Date -Y
---
--- returns "-Y".
local function get_parameter_prefix()
  local cursor = vim.api.nvim_win_get_cursor(0)

  local line =
    vim.api.nvim_buf_get_lines(
      0,
      cursor[1] - 1,
      cursor[1],
      false
    )[1] or ''

  local before_cursor =
    line:sub(1, cursor[2])

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

  local before =
    line:sub(1, col)

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

  local segment =
    before:match('[|;]%s*(.-)$')
    or before

  return segment:match(
    '^%s*([%w%-_]+)'
  )
end

-- ---------------------------------------------------------------------------
-- Import parsing
-- ---------------------------------------------------------------------------

local function extract_path(s)
  local path

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

  if not path then
    path =
      s:match(
        '^(%S+%.psm?1)'
      )
  end

  if not path then
    return nil
  end

  return path:match(
    '^%.[\\/](.+)'
  ) or path:match(
    '^%$PSScriptRoot[\\/](.+)'
  )
end

local function parse_import(line)
  local code =
    line:match('^(.-)#')
    or line

  -- Dot source
  local after =
    code:match(
      '^%s*%.%s+(.*)'
    )

  if after then
    local ref =
      extract_path(after)

    if ref then
      return ref
    end
  end

  -- Import-Module
  after =
    code:match(
      '^%s*[Ii]mport%-[Mm]odule%s+(.*)'
    )

  if after then
    local after_name =
      after:match(
        '^%-[Nn]ame%s+(.*)'
      )

    local ref =
      extract_path(
        after_name or after
      )

    if ref then
      return ref
    end
  end

  -- using module
  after =
    code:match(
      '^%s*[Uu]sing%s+[Mm]odule%s+(.*)'
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
-- File discovery
-- ---------------------------------------------------------------------------

local function collect_files(current_file)
  local current_dir =
    vim.fn.fnamemodify(
      current_file,
      ':h'
    )

  local seen = {
    [current_file] = true,
  }

  local result = {}

  -- Sibling files
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
      vim.fn.fnamemodify(
        file,
        ':p'
      )

    if not seen[full] then
      seen[full] = true
      table.insert(
        result,
        full
      )
    end
  end

  -- Imported files
  local queue = {
    current_file,
  }

  while #queue > 0 do
    local file =
      table.remove(
        queue,
        1
      )

    local file_dir =
      vim.fn.fnamemodify(
        file,
        ':h'
      )

    local ok
    local lines

    if file == current_file then
      lines =
        vim.api.nvim_buf_get_lines(
          0,
          0,
          -1,
          false
        )

      ok = true
    else
      ok, lines =
        pcall(
          vim.fn.readfile,
          file
        )
    end

    if ok and lines then
      for _, line in ipairs(lines) do
        local ref =
          parse_import(line)

        if ref then
          ref =
            normalise_path(ref)

          local full =
            vim.fn.fnamemodify(
              file_dir
                .. sep
                .. ref,
              ':p'
            )

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

  return result
end

-- ---------------------------------------------------------------------------
-- Parse PowerShell files
-- ---------------------------------------------------------------------------

local function parse_file(
  file,
  items,
  func_params
)
  local ok, lines =
    pcall(
      vim.fn.readfile,
      file
    )

  if not ok or not lines then
    return
  end

  local filename =
    vim.fn.fnamemodify(
      file,
      ':t'
    )

  local seen_vars = {}
  local in_param_block = false
  local paren_depth = 0
  local current_func = nil

  local CompletionItemKind =
    require('cmp.types').lsp.CompletionItemKind

  for i, line in ipairs(lines) do

    -- Function declaration
    local func_name =
      line:match(
        '^%s*[Ff]unction%s+([%w%-_]+)'
      )

    if func_name then
      current_func = func_name

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

    -- Param block
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

      if paren_depth <= 0 then
        in_param_block = false
      end
    end

    -- Variables
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
    os.clock()

  if cache.file_set == file_set_key
    and (now - cache.timestamp) < CACHE_TTL
  then
    local items =
      vim.deepcopy(
        cache.items
      )

    local calling =
      self._calling_function()

    if calling
      and cache.func_params[
        calling:lower()
      ]
    then
      vim.list_extend(
        items,
        cache.func_params[
          calling:lower()
        ]
      )
    end

    callback({
      items = items,
    })

    return
  end

  local items = {}
  local func_params = {}

  for _, file in ipairs(ps_files) do
    parse_file(
      file,
      items,
      func_params
    )
  end

  cache.items =
    vim.deepcopy(items)

  cache.func_params =
    func_params

  cache.file_set =
    file_set_key

  cache.timestamp =
    now

  local calling =
    self._calling_function()

  if calling then
    local key =
      calling:lower()

    if func_params[key] then
      vim.list_extend(
        items,
        func_params[key]
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
--
-- PSES built-in parameters are reported as:
--
--     kind = Variable
--     label = Year
--
-- We must NOT require the label itself to contain "-".
--
-- Instead, inspect the actual cursor context:
--
--     Get-Date -
--              ^
--
-- If we are completing after "-", a Variable completion from PSES is
-- treated visually as a PowerShell parameter.
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

  -- Our project-local source
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

  -- PSES / nvim-lsp
  if entry.source.name == 'nvim_lsp' then
    local item =
      entry:get_completion_item()

    -- LSP CompletionItemKind.Variable = 6
    if item.kind == 6 then
      -- The important distinction:
      --
      --     $Year      -> variable
      --     -Year      -> parameter
      --
      -- PSES gives us "Year" as a Variable. Determine whether the
      -- completion is being requested in "-parameter" context.
      if is_parameter_context() then
        vim_item.kind = 'Param'

        -- Make the display explicitly look like a PowerShell parameter.
        local abbr =
          vim_item.abbr or item.label or ''

        -- Don't add another "-" if cmp/PSES already supplied one.
        if not abbr:match('^%-') then
          vim_item.abbr =
            '-' .. abbr
        end
      end
    end

    return true
  end

  return false
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

    local current_dir =
      vim.fn.fnamemodify(
        current_file,
        ':h'
      )

    local out = {
      '=== PS Completion Debug ===',
      'Current file: ' .. current_file,
      'Current dir:  ' .. current_dir,
      '',
      '--- Current completion context ---',
      'Parameter context: '
        .. tostring(
          is_parameter_context()
        ),
      'Parameter prefix: '
        .. tostring(
          get_parameter_prefix()
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

        local ref_norm =
          normalise_path(ref)

        local full =
          vim.fn.fnamemodify(
            current_dir
              .. sep
              .. ref_norm,
            ':p'
          )

        local readable =
          vim.fn.filereadable(full) == 1

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
            full
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

