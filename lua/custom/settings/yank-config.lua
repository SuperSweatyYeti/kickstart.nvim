-- NOTE: This config changes the default behavior of yanking and buffers such that my paste buffer never gets overridden unless i explicitly yank something else. Changing and deleting does not overwrite the clipboard and unnamed buffer with this config.
-- NOTE: I can toggle this behavior off with :TogglePreserveYank .

-- Deep compare registers
local function reg_equal(a, b)
  return vim.deep_equal(a.regcontents, b.regcontents) and a.regtype == b.regtype
end

-- Toggle to enable/disable the preservation behavior
vim.g.preserve_yank_enabled = true

-- After destructive op, restore unnamed and clipboard registers (if toggle is enabled)
local function preserve_yank_and_clipboard(keys)
  return function()
    if not vim.g.preserve_yank_enabled then
      if keys:sub(1, 1) == 'c' then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'n', false)
      else
        vim.cmd.normal { keys, bang = true }
      end
      return
    end

    local yank = vim.fn.getreginfo '0' -- Last yank
    local unnamed_before = vim.fn.getreginfo '"'
    local clipboard_before = vim.fn.getreginfo '+'

    -- Use feedkeys for change commands (to enter insert mode), otherwise normal!
    if keys:sub(1, 1) == 'c' then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'n', false)
    else
      vim.cmd.normal { keys, bang = true }
    end

    -- Schedule restore so it doesn't interfere with insert mode
    vim.schedule(function()
      -- Restore unnamed register
      vim.fn.setreg('"', yank.regcontents, yank.regtype)

      -- Restore system clipboard (if it was overwritten)
      local clipboard_after = vim.fn.getreginfo '+'
      if not reg_equal(clipboard_before, clipboard_after) then
        vim.fn.setreg('+', clipboard_before.regcontents, clipboard_before.regtype)
      end

      -- Push the overwritten unnamed to "1" so yankring still tracks it
      vim.fn.setreg('1', unnamed_before.regcontents, unnamed_before.regtype)
    end)
  end
end

-- All destructive motions that shouldn't overwrite the last yank or system clipboard
local destructive_motions = {
  -- Keep the normal 'dd' behavior
  -- we like this
  -- { mode = 'n', key = 'dd' },
  { mode = 'n', key = 'D' },
  { mode = 'n', key = 'x' },
  { mode = 'n', key = 's' },
  { mode = 'n', key = 'S' },
  -- Changes
  { mode = 'n', key = 'cl' },
  { mode = 'n', key = 'ch' },
  { mode = 'n', key = 'cw' },
  { mode = 'n', key = 'cW' },
  { mode = 'n', key = 'ciw' },
  { mode = 'n', key = 'ciW' },
  { mode = 'n', key = 'ci)' },
  { mode = 'n', key = 'ci(' },
  { mode = 'n', key = 'ci]' },
  { mode = 'n', key = 'ci[' },
  { mode = 'n', key = 'ci}' },
  { mode = 'n', key = 'ci{' },
  { mode = 'n', key = 'ci"' },
  { mode = 'n', key = 'ci>' },
  { mode = 'n', key = 'ci<' },
  { mode = 'n', key = "ci'" },
  { mode = 'n', key = 'ci`' },
  { mode = 'n', key = 'caw' },
  { mode = 'n', key = 'caW' },
  { mode = 'n', key = 'ca)' },
  { mode = 'n', key = 'ca(' },
  { mode = 'n', key = 'ca]' },
  { mode = 'n', key = 'ca[' },
  { mode = 'n', key = 'ca{' },
  { mode = 'n', key = 'ca}' },
  { mode = 'n', key = 'ca>' },
  { mode = 'n', key = 'ca<' },
  { mode = 'n', key = 'ca"' },
  { mode = 'n', key = "ca'" },
  { mode = 'n', key = 'ca`' },
  { mode = 'n', key = 'cap' },
  { mode = 'n', key = 'cip' },
  -- deletes
  { mode = 'n', key = 'dl' },
  { mode = 'n', key = 'dh' },
  { mode = 'n', key = 'diw' },
  { mode = 'n', key = 'diW' },
  { mode = 'n', key = 'daw' },
  { mode = 'n', key = 'daW' },
  { mode = 'n', key = 'dap' },
  { mode = 'n', key = 'dip' },
  -- visual mode
  -- { mode = 'v', key = 'd' },
  { mode = 'v', key = 'c' },
  { mode = 'v', key = 'x' },
  { mode = 'v', key = 'p' },
}

-- Apply the mappings
for _, map in ipairs(destructive_motions) do
  vim.keymap.set(map.mode, map.key, preserve_yank_and_clipboard(map.key), {
    desc = 'Preserve yank & clipboard',
    noremap = true,
    silent = true,
  })
end

-- Optional command to toggle the behavior on/off
vim.api.nvim_create_user_command('TogglePreserveYank', function()
  vim.g.preserve_yank_enabled = not vim.g.preserve_yank_enabled
  print('Preserve yank & clipboard is now ' .. (vim.g.preserve_yank_enabled and 'enabled' or 'disabled'))
end, { desc = 'Toggle preserving yank/clipboard during destructive operations' })

