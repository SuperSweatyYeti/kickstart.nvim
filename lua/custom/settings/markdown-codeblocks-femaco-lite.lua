-- Minimal floating code block editor (replaces FeMaco)
-- FeMaco is broken with nvim-treesitter main branch rewrite
-- This uses only Neovim's built-in treesitter APIs

local M = {}

function M.edit_code_block()
  local node = vim.treesitter.get_node()
  -- Walk up to find the fenced_code_block
  while node and node:type() ~= 'fenced_code_block' do
    node = node:parent()
  end
  if not node then
    vim.notify('No code block found', vim.log.levels.WARN)
    return
  end

  -- Find the fence delimiters and content
  local lang, content_node
  local open_fence_row, close_fence_row

  for child in node:iter_children() do
    local ctype = child:type()
    if ctype == 'info_string' then
      for sub in child:iter_children() do
        if sub:type() == 'language' then
          lang = vim.treesitter.get_node_text(sub, 0)
        end
      end
    elseif ctype == 'code_fence_content' then
      content_node = child
    elseif ctype == 'fenced_code_block_delimiter' then
      local row = child:range()
      if not open_fence_row then
        open_fence_row = row
      else
        close_fence_row = row
      end
    end
  end

  if not content_node then
    return
  end
  if not open_fence_row or not close_fence_row then
    return
  end

  -- Content lives on lines between the opening fence and closing fence
  -- (open_fence_row + 1) through (close_fence_row - 1) inclusive
  local content_start_row = open_fence_row + 1
  local content_end_row = close_fence_row -- exclusive for nvim_buf_set_lines

  local lines = vim.api.nvim_buf_get_lines(0, content_start_row, content_end_row, false)
  local source_buf = vim.api.nvim_get_current_buf()

  -- Map language names to file extensions for the temp file
  local ext_map = {
    powershell = 'ps1',
    bash = 'sh',
    python = 'py',
    javascript = 'js',
    typescript = 'ts',
    lua = 'lua',
    yaml = 'yml',
    markdown = 'md',
    html = 'html',
    css = 'css',
    json = 'json',
    c = 'c',
    cpp = 'cpp',
    rust = 'rs',
    go = 'go',
    vim = 'vim',
  }

  local ft = lang or 'text'
  local ext = ext_map[ft] or ft
  local tmpfile = vim.fn.tempname() .. '.' .. ext

  -- Only write back if user explicitly saved
  local has_saved = false

  -- Track the content line range in the source buffer
  -- These get updated after each write-back so added/removed lines are handled
  local src_content_start = content_start_row
  local src_content_end = content_end_row

  -- Create float
  local width = math.floor(vim.o.columns * 0.80)
  local height = math.floor(vim.o.lines * 0.75)
  local buf = vim.api.nvim_create_buf(false, false)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    focusable = true,
    border = 'rounded',
    title = ' ' .. ft .. ' ',
    title_pos = 'center',
    zindex = 10,
  })

  vim.cmd('file ' .. vim.fn.fnameescape(tmpfile))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = ft
  vim.bo[buf].bufhidden = 'wipe'

  vim.wo[win].number = true
  vim.wo[win].relativenumber = true
  vim.wo[win].signcolumn = 'yes'

  pcall(vim.treesitter.start)
  vim.cmd 'silent! write!'
  vim.cmd('doautocmd FileType ' .. ft)

  --- Replace the content lines between the fences in the source buffer
  local function write_back()
    if not vim.api.nvim_buf_is_valid(source_buf) then
      return
    end
    local new_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    -- Replace the entire content region (line-wise, between the fences)
    vim.api.nvim_buf_set_lines(source_buf, src_content_start, src_content_end, false, new_lines)
    -- Update the end boundary to account for added/removed lines
    src_content_end = src_content_start + #new_lines
    has_saved = true
  end

  -- :w writes back to source immediately
  vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = buf,
    callback = write_back,
  })

  -- Clean up on close
  vim.api.nvim_create_autocmd('WinClosed', {
    buffer = buf,
    once = true,
    callback = function()
      -- Write back final state only if user saved at least once
      if has_saved and vim.api.nvim_buf_is_valid(buf) then
        write_back()
      end
      vim.fn.delete(tmpfile)
    end,
  })

  -- q = close and discard
  vim.keymap.set('n', 'q', function()
    has_saved = false
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, desc = 'Close code block editor (discard changes)' })

  -- <leader>cb = save and close
  vim.keymap.set('n', '<leader>cb', function()
    vim.cmd 'silent! write!'
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf, desc = 'Save code block and close' })
end

vim.keymap.set('n', '<leader>cb', function()
  M.edit_code_block()
end, { noremap = true, silent = true, desc = '[c]ode [b]lock markdown open in window' })

return M
