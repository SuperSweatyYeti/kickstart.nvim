-- NOTE: SearchReplaceAll - Project-wide search and replace using ripgrep + quickfix list.
-- Uses ripgrep (rg) to find all matches across the project, populates the quickfix list,
-- then steps through each entry one at a time, highlighting the current quickfix line
-- and the match on the actual line, prompting you to confirm each replacement.
-- Accepted replacements are removed from the quickfix list so only remaining/skipped items stay.
--
-- Usage:
--   :SearchReplaceAll <search> <replace> [true|false] [true|false] [true|false]
--   <leader>sRAnn  (interactive prompt - normal/literal search, no hidden files)
--   <leader>sRAnh  (interactive prompt - normal/literal search, include hidden files)
--   <leader>sRArn  (interactive prompt - regex search, no hidden files)
--   <leader>sRArh  (interactive prompt - regex search, include hidden files)
--
-- The third argument controls case sensitivity (defaults to true = case sensitive).
-- The fourth argument controls regex mode (defaults to false = literal/normal).
-- The fifth argument controls hidden files (defaults to false = no hidden files).
-- The quickfix window is automatically closed afterwards, whether you finish or abort.
-- Your original buffer and cursor position are restored when done.
-- The current quickfix entry is highlighted as you step through each match.
-- The actual match text is highlighted on the line so you can see exactly what will change.
--
-- During the prompt:
--   y = replace this match
--   n = skip this match (move forward)
--   a = replace all remaining
--   q / Esc = quit
--   u = undo last accepted replacement
--   j / Ctrl+n = preview next match without deciding (skip forward)
--   k / Ctrl+p = preview previous match without deciding (go back)

-- NOTE: nice aliases for quickfix do
-- Aliases: :Qdo → :cdo, :Qfdo → :cfdo
vim.api.nvim_create_user_command('Qdo', function(opts)
  vim.cmd('cdo ' .. opts.args)
end, { nargs = '+' })
vim.api.nvim_create_user_command('Qfdo', function(opts)
  vim.cmd('cfdo ' .. opts.args)
end, { nargs = '+' })

-- Escape special characters for vim regex patterns
local function escape_vim_regex(str)
  return vim.fn.escape(str, [[/\.*$^~[]])
end

-- Escape special characters for shell arguments
local function escape_shell_arg(str)
  return vim.fn.shellescape(str)
end

-- Highlight namespaces
local qf_hl_ns = vim.api.nvim_create_namespace 'SearchReplaceAllQfHighlight'
local match_hl_ns = vim.api.nvim_create_namespace 'SearchReplaceAllMatchHighlight'

-- Find the quickfix window (if open) and return its window ID and buffer
local function get_qf_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == 'quickfix' then
      return win, buf
    end
  end
  return nil, nil
end

-- Highlight a specific quickfix line (1-indexed), clearing any previous highlight
local function highlight_qf_line(idx)
  local qf_win, qf_buf = get_qf_win()
  if not qf_win or not qf_buf then
    return
  end

  vim.api.nvim_buf_clear_namespace(qf_buf, qf_hl_ns, 0, -1)

  local qf_line_count = vim.api.nvim_buf_line_count(qf_buf)
  if idx >= 1 and idx <= qf_line_count then
    vim.api.nvim_buf_add_highlight(qf_buf, qf_hl_ns, 'Visual', idx - 1, 0, -1)
    vim.api.nvim_win_set_cursor(qf_win, { idx, 0 })
  end
end

-- Highlight the match on the actual source line.
local function highlight_match(search, entry, use_regex, case_sensitive)
  local bufnr = vim.fn.bufnr(entry.filename)
  if bufnr == -1 or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, match_hl_ns, 0, -1)
    end
  end

  local lnum = entry.lnum
  local lines = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)
  if #lines == 0 then
    return
  end

  local line_text = lines[1]
  local col_start = nil
  local col_end = nil

  if not use_regex then
    local search_lower = case_sensitive and search or search:lower()
    local line_search = case_sensitive and line_text or line_text:lower()

    local qf_col = (entry.col or 1) - 1
    local found = line_search:find(search_lower, qf_col + 1, true)
    if found then
      col_start = found - 1
      col_end = col_start + #search
    else
      found = line_search:find(search_lower, 1, true)
      if found then
        col_start = found - 1
        col_end = col_start + #search
      end
    end
  else
    local pattern = case_sensitive and search or ('\\c' .. search)
    local ok, result = pcall(vim.fn.matchstrpos, line_text, pattern)
    if ok and result[2] >= 0 then
      col_start = result[2]
      col_end = result[3]
    end
  end

  if col_start and col_end then
    vim.api.nvim_buf_add_highlight(bufnr, match_hl_ns, 'IncSearch', lnum - 1, col_start, col_end)
  end
end

-- Clear match highlights from all buffers
local function clear_match_highlights()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, match_hl_ns, 0, -1)
    end
  end
end

-- Remove an entry from the quickfix list by index and refresh the window
local function remove_qf_entry(idx)
  local qf_list = vim.fn.getqflist()
  if idx >= 1 and idx <= #qf_list then
    table.remove(qf_list, idx)
    vim.fn.setqflist({}, 'r', {
      items = qf_list,
      title = vim.fn.getqflist({ title = 0 }).title,
    })
  end
end

-- Re-insert an entry into the quickfix list at the given index
local function insert_qf_entry(idx, entry)
  local qf_list = vim.fn.getqflist()
  table.insert(qf_list, idx, {
    filename = entry.filename,
    lnum = entry.lnum,
    col = entry.col,
    text = entry.text,
  })
  vim.fn.setqflist({}, 'r', {
    items = qf_list,
    title = vim.fn.getqflist({ title = 0 }).title,
  })
end

-- Main function
function SearchReplaceAll(search, replace, case_sensitive, use_regex, include_hidden)
  if not search or search == '' then
    vim.notify('[SearchReplaceAll] Search term cannot be empty', vim.log.levels.WARN)
    return
  end

  if not replace then
    replace = ''
  end

  if case_sensitive == nil then
    case_sensitive = true
  end

  if use_regex == nil then
    use_regex = false
  end

  if include_hidden == nil then
    include_hidden = false
  end

  local original_buf = vim.api.nvim_get_current_buf()
  local original_cursor = vim.api.nvim_win_get_cursor(0)

  local rg_cmd = 'rg --vimgrep --no-heading'
  if not use_regex then
    rg_cmd = rg_cmd .. ' --fixed-strings'
  end
  if not case_sensitive then
    rg_cmd = rg_cmd .. ' --ignore-case'
  else
    rg_cmd = rg_cmd .. ' --case-sensitive'
  end
  if include_hidden then
    rg_cmd = rg_cmd .. ' --hidden'
  end
  rg_cmd = rg_cmd .. ' ' .. escape_shell_arg(search)

  local output = vim.fn.systemlist(rg_cmd)

  if vim.v.shell_error ~= 0 or #output == 0 then
    vim.notify('[SearchReplaceAll] No matches found for: ' .. search, vim.log.levels.WARN)
    return
  end

  local qf_entries = {}
  for _, line in ipairs(output) do
    local file, lnum, col, text = line:match '^(.+):(%d+):(%d+):(.*)$'
    if file and lnum and col then
      table.insert(qf_entries, {
        filename = file,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text,
      })
    end
  end

  if #qf_entries == 0 then
    vim.notify('[SearchReplaceAll] Failed to parse ripgrep output', vim.log.levels.ERROR)
    return
  end

  local mode_label = use_regex and 'regex' or 'literal'
  local hidden_label = include_hidden and ', +hidden' or ''
  vim.fn.setqflist({}, 'r', {
    title = 'SearchReplaceAll (' .. mode_label .. hidden_label .. '): ' .. search .. ' → ' .. replace,
    items = qf_entries,
  })
  vim.cmd 'copen'

  local qf_win = get_qf_win()
  if qf_win then
    vim.api.nvim_set_option_value('cursorline', false, { win = qf_win })
  end

  local sub_search = use_regex and search or escape_vim_regex(search)
  local sub_replace = use_regex and replace or escape_vim_regex(replace)
  local case_flag = case_sensitive and '' or 'i'

  local function restore_position()
    clear_match_highlights()

    local _, qf_buf = get_qf_win()
    if qf_buf then
      vim.api.nvim_buf_clear_namespace(qf_buf, qf_hl_ns, 0, -1)
    end
    vim.cmd 'cclose'

    if vim.api.nvim_buf_is_valid(original_buf) then
      vim.api.nvim_set_current_buf(original_buf)
      local line_count = vim.api.nvim_buf_line_count(original_buf)
      local row = math.min(original_cursor[1], line_count)
      local line = vim.api.nvim_buf_get_lines(original_buf, row - 1, row, false)[1] or ''
      local col = math.min(original_cursor[2], #line)
      vim.api.nvim_win_set_cursor(0, { row, col })
    end

    vim.cmd 'echo ""'
  end

  local replaced_count = 0
  local skipped_count = 0
  local total_count = #qf_entries

  -- We maintain a parallel list that tracks the state of each entry:
  --   'pending'  = not yet decided
  --   'replaced' = accepted and replaced
  --   'skipped'  = skipped with 'n'
  local entry_states = {}
  for i = 1, total_count do
    entry_states[i] = 'pending'
  end

  -- Undo stack: each entry records what we need to reverse a replacement
  -- { entry_idx = <int>, bufnr = <int> }
  local undo_stack = {}

  -- Current position in the ORIGINAL entries list (1..total_count)
  local current_entry = 1

  -- Map from original entry index to current quickfix line index.
  -- This recalculates each time because the qf list shrinks when entries are removed.
  local function entry_to_qf_idx(entry_idx)
    local qf_idx = 0
    for i = 1, entry_idx do
      if entry_states[i] ~= 'replaced' then
        qf_idx = qf_idx + 1
      end
    end
    return qf_idx
  end

  -- Find the next non-replaced entry at or after the given index. Returns nil if none.
  local function next_visible(from)
    for i = from, total_count do
      if entry_states[i] ~= 'replaced' then
        return i
      end
    end
    return nil
  end

  -- Find the previous non-replaced entry before the given index. Returns nil if none.
  local function prev_visible(from)
    for i = from, 1, -1 do
      if entry_states[i] ~= 'replaced' then
        return i
      end
    end
    return nil
  end

  -- Find the next pending entry at or after the given index. Returns nil if none.
  local function next_pending(from)
    for i = from, total_count do
      if entry_states[i] == 'pending' then
        return i
      end
    end
    return nil
  end

  -- Find the previous pending entry before the given index. Returns nil if none.
  local function prev_pending(from)
    for i = from, 1, -1 do
      if entry_states[i] == 'pending' then
        return i
      end
    end
    return nil
  end

  -- Show a specific entry (jump to it, highlight qf + match, show prompt)
  local function show_entry(entry_idx)
    local qf_idx = entry_to_qf_idx(entry_idx)
    local current_qf_list = vim.fn.getqflist()

    if qf_idx < 1 or qf_idx > #current_qf_list then
      return
    end

    vim.cmd('cc ' .. qf_idx)
    highlight_qf_line(qf_idx)
    highlight_match(search, qf_entries[entry_idx], use_regex, case_sensitive)

    local entry = qf_entries[entry_idx]
    local short_file = vim.fn.fnamemodify(entry.filename, ':~:.')
    local pending_count = 0
    for _, s in ipairs(entry_states) do
      if s == 'pending' then
        pending_count = pending_count + 1
      end
    end

    local state = entry_states[entry_idx]
    local state_label = ''
    if state == 'skipped' then
      state_label = ' [skipped]'
    end

    local undo_label = #undo_stack > 0 and '(u)ndo ' or ''
    local prompt = string.format(
      '[%d/%d] (%d pending) %s:%d%s  "%s" → "%s"  (y)es (n)o (a)ll %s(q)uit  j/k: browse: ',
      entry_idx,
      total_count,
      pending_count,
      short_file,
      entry.lnum,
      state_label,
      search,
      replace,
      undo_label
    )

    vim.api.nvim_echo({ { prompt, 'Question' } }, false, {})
    vim.cmd 'redraw'
  end

  local function step()
    -- Find next pending entry from current position
    local pending = next_pending(current_entry)
    if not pending then
      -- Try wrapping from the beginning
      pending = next_pending(1)
    end

    if not pending then
      vim.notify('[SearchReplaceAll] Done! Replaced: ' .. replaced_count .. ', Skipped: ' .. skipped_count, vim.log.levels.INFO)
      restore_position()
      return
    end

    current_entry = pending
    show_entry(current_entry)

    local ok, char = pcall(vim.fn.getcharstr)
    if not ok then
      vim.notify('[SearchReplaceAll] Aborted! Replaced: ' .. replaced_count .. ', Skipped: ' .. skipped_count, vim.log.levels.WARN)
      restore_position()
      return
    end

    -- Ctrl+n = \x0e, Ctrl+p = \x10
    if char == 'y' or char == 'Y' then
      -- Get qf index BEFORE marking as replaced so the index is correct
      local qf_idx = entry_to_qf_idx(current_entry)

      -- Record the buffer for undo
      local entry = qf_entries[current_entry]
      local bufnr = vim.fn.bufnr(entry.filename)

      pcall(vim.cmd, 's/' .. sub_search .. '/' .. sub_replace .. '/g' .. case_flag)
      replaced_count = replaced_count + 1
      entry_states[current_entry] = 'replaced'
      remove_qf_entry(qf_idx)

      -- Push onto undo stack
      table.insert(undo_stack, {
        entry_idx = current_entry,
        bufnr = bufnr,
      })

      current_entry = current_entry + 1
      vim.schedule(step)
    elseif char == 'u' or char == 'U' then
      if #undo_stack == 0 then
        vim.api.nvim_echo({ { 'Nothing to undo.', 'WarningMsg' } }, false, {})
        vim.cmd 'redraw'
        vim.schedule(step)
      else
        local last = table.remove(undo_stack)
        local undo_entry_idx = last.entry_idx
        local undo_bufnr = last.bufnr

        -- Undo the substitution in the target buffer
        if undo_bufnr and vim.api.nvim_buf_is_valid(undo_bufnr) then
          local current_win_buf = vim.api.nvim_win_get_buf(0)
          if current_win_buf ~= undo_bufnr then
            vim.api.nvim_set_current_buf(undo_bufnr)
          end
          pcall(vim.cmd, 'undo')
          -- Switch back if we changed buffers
          if current_win_buf ~= undo_bufnr then
            vim.api.nvim_set_current_buf(current_win_buf)
          end
        end

        -- Restore entry state to pending
        entry_states[undo_entry_idx] = 'pending'
        replaced_count = replaced_count - 1

        -- Re-insert into quickfix list at the correct position
        local qf_idx = entry_to_qf_idx(undo_entry_idx)
        insert_qf_entry(qf_idx, qf_entries[undo_entry_idx])

        -- Jump back to the undone entry
        current_entry = undo_entry_idx

        vim.notify('[SearchReplaceAll] Undid replacement at entry ' .. undo_entry_idx, vim.log.levels.INFO)
        vim.schedule(step)
      end
    elseif char == 'n' or char == 'N' then
      skipped_count = skipped_count + 1
      entry_states[current_entry] = 'skipped'
      current_entry = current_entry + 1
      vim.schedule(step)
    elseif char == 'j' or char == '\x0e' then
      -- j or Ctrl+n: browse to next visible (non-replaced) entry, wrapping around
      local next_entry = next_visible(current_entry + 1)
      if not next_entry then
        next_entry = next_visible(1)
      end
      if next_entry then
        current_entry = next_entry
      end
      show_entry(current_entry)
      vim.schedule(step)
    elseif char == 'k' or char == '\x10' then
      -- k or Ctrl+p: browse to previous visible (non-replaced) entry, wrapping around
      local prev_entry = prev_visible(current_entry - 1)
      if not prev_entry then
        prev_entry = prev_visible(total_count)
      end
      if prev_entry then
        current_entry = prev_entry
      end
      show_entry(current_entry)
      vim.schedule(step)
    elseif char == 'a' or char == 'A' then
      for i = 1, total_count do
        if entry_states[i] == 'pending' then
          -- Get qf index BEFORE marking as replaced so the index is correct
          local qf_idx = entry_to_qf_idx(i)
          local current_qf_list = vim.fn.getqflist()
          if qf_idx >= 1 and qf_idx <= #current_qf_list then
            vim.cmd('cc ' .. qf_idx)
            highlight_qf_line(qf_idx)
            vim.cmd 'redraw'
            pcall(vim.cmd, 's/' .. sub_search .. '/' .. sub_replace .. '/g' .. case_flag)
            replaced_count = replaced_count + 1
            entry_states[i] = 'replaced'
            remove_qf_entry(qf_idx)
          end
        end
      end
      vim.notify('[SearchReplaceAll] Done! Replaced: ' .. replaced_count .. ', Skipped: ' .. skipped_count, vim.log.levels.INFO)
      restore_position()
      return
    elseif char == 'q' or char == 'Q' or char == '\27' then
      local remaining = 0
      for _, s in ipairs(entry_states) do
        if s == 'pending' then
          remaining = remaining + 1
        end
      end
      skipped_count = skipped_count + remaining
      vim.notify('[SearchReplaceAll] Stopped. Replaced: ' .. replaced_count .. ', Skipped: ' .. skipped_count, vim.log.levels.INFO)
      restore_position()
      return
    else
      vim.api.nvim_echo({ { 'Invalid key. Press y/n/a/u/q or j/k to browse', 'WarningMsg' } }, false, {})
      vim.cmd 'redraw'
      vim.schedule(step)
    end
  end

  -- Start stepping
  vim.defer_fn(function()
    local edit_win = nil
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype ~= 'quickfix' then
        edit_win = win
        break
      end
    end
    if edit_win then
      vim.api.nvim_set_current_win(edit_win)
    end

    step()
  end, 200)
end

-- User command: :SearchReplaceAll <search> <replace> [case_sensitive] [use_regex] [include_hidden]
vim.api.nvim_create_user_command('SearchReplaceAll', function(opts)
  local args = opts.fargs
  local search = args[1]
  local replace = args[2] or ''
  local case_sensitive = true
  local use_regex = false
  local include_hidden = false

  if args[3] then
    case_sensitive = args[3] ~= 'false' and args[3] ~= '0' and args[3] ~= 'no'
  end

  if args[4] then
    use_regex = args[4] == 'true' or args[4] == '1' or args[4] == 'yes'
  end

  if args[5] then
    include_hidden = args[5] == 'true' or args[5] == '1' or args[5] == 'yes'
  end

  SearchReplaceAll(search, replace, case_sensitive, use_regex, include_hidden)
end, {
  nargs = '+',
  desc = 'Search and replace across project using ripgrep + quickfix',
})

-- Helper to run the interactive prompts (shared by all keymaps)
local function search_replace_prompt(use_regex, include_hidden)
  local mode_label = use_regex and 'regex' or 'normal'
  local hidden_label = include_hidden and ', +hidden' or ''
  vim.ui.input({ prompt = 'Search term (' .. mode_label .. hidden_label .. '): ' }, function(search)
    if not search or search == '' then
      return
    end
    vim.notify('[SearchReplaceAll]: Search Term (' .. mode_label .. hidden_label .. '): ' .. search, vim.log.levels.INFO)

    vim.ui.input({ prompt = 'Replace with: ' }, function(replace)
      if replace == nil then
        return
      end
      vim.notify('[SearchReplaceAll]: Replace With: ' .. replace, vim.log.levels.INFO)

      vim.ui.input({ prompt = 'Case sensitive? (y/n) [y]: ' }, function(case_input)
        local case_sensitive = true

        if case_input == nil then
          vim.notify('[SearchReplaceAll]: Cancelled.', vim.log.levels.WARN)
          return
        end

        if case_input == '' then
          case_sensitive = true
        elseif case_input:lower() == 'n' or case_input:lower() == 'no' then
          case_sensitive = false
        elseif case_input:lower() == 'y' or case_input:lower() == 'yes' then
          case_sensitive = true
        else
          vim.notify('[SearchReplaceAll]: Invalid input "' .. case_input .. '". Please enter y or n.', vim.log.levels.ERROR)
          return
        end

        SearchReplaceAll(search, replace, case_sensitive, use_regex, include_hidden)
      end)
    end)
  end)
end

-- Which-key groups
require('which-key').add {
  { mode = { 'n' }, { '<leader>sR', group = '[s]earch [R]eplace', hidden = false } },
  { mode = { 'n' }, { '<leader>sRA', group = '[s]earch [R]eplace [A]ll include hidden files', hidden = true } },
  { mode = { 'n' }, { '<leader>sRa', group = '[s]earch [R]eplace [a]ll', hidden = false } },
}
-- <leader>sRAn — normal/literal search, include hidden files
vim.keymap.set('n', '<leader>sRAn', function()
  search_replace_prompt(false, true)
end, { desc = '[s]earch [R]eplace [A]ll include hidden [n]ormal pattern search (literal)' })

-- <leader>sRAr — regex search, include hidden files
vim.keymap.set('n', '<leader>sRAr', function()
  search_replace_prompt(true, true)
end, { desc = '[s]earch [R]eplace [A]ll include hidden [r]egex pattern search' })

-- <leader>sRan — normal search, no hidden files
vim.keymap.set('n', '<leader>sRan', function()
  search_replace_prompt(true, true)
end, { desc = '[s]earch [R]eplace [a]ll [n]ormal pattern search (literal)' })

-- <leader>sRar — regex search, no hidden files
vim.keymap.set('n', '<leader>sRar', function()
  search_replace_prompt(true, true)
end, { desc = '[s]earch [R]eplace [a]ll [r]egex pattern search' })
