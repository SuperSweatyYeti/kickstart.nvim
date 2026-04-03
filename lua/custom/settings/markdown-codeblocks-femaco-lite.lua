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

  -- Find language and content nodes
  local lang, content_node
  for child in node:iter_children() do
    if child:type() == 'info_string' then
      for sub in child:iter_children() do
        if sub:type() == 'language' then
          lang = vim.treesitter.get_node_text(sub, 0)
        end
      end
    elseif child:type() == 'code_fence_content' then
      content_node = child
    end
  end

  if not content_node then return end

  local sr, sc, er, ec = content_node:range()
  local lines = vim.api.nvim_buf_get_text(0, sr, sc, er, ec, {})
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

  -- Create float (same dimensions as old FeMaco config: 80% x 75%)
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
    zindex = 10, -- below treesitter-context's default of 20, so context renders on top
  })

  -- Set the buffer to a temp file so LSP attaches
  vim.cmd('file ' .. vim.fn.fnameescape(tmpfile))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = ft
  vim.bo[buf].bufhidden = 'wipe'

  -- Remove 'minimal' style restrictions so treesitter-context can render properly
  vim.wo[win].number = true
  vim.wo[win].relativenumber = true
  vim.wo[win].signcolumn = 'yes'

  -- Start treesitter for highlighting + context
  pcall(vim.treesitter.start)

  -- Write the temp file so LSP sees it
  vim.cmd('silent! write!')

  -- Trigger FileType so treesitter-context attaches to this buffer
  vim.cmd('doautocmd FileType ' .. ft)

  -- Write back to source on save
  vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = buf,
    callback = function()
      local new_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      vim.api.nvim_buf_set_text(source_buf, sr, sc, er, ec, new_lines)
      -- Update the range end for subsequent saves
      er = sr + #new_lines
      ec = 0
    end,
  })

  -- Clean up on close
  vim.api.nvim_create_autocmd('WinClosed', {
    buffer = buf,
    once = true,
    callback = function()
      -- Write back final state
      if vim.api.nvim_buf_is_valid(buf) then
        local new_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        vim.api.nvim_buf_set_text(source_buf, sr, sc, er, ec, new_lines)
      end
      -- Clean up temp file
      vim.fn.delete(tmpfile)
    end,
  })

  -- Close with q
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })
end

-- Keymap (same as old FeMaco binding)
vim.keymap.set('n', '<leader>cb', function()
  M.edit_code_block()
end, { noremap = true, silent = true, desc = '[c]ode [b]lock markdown open in window' })

return M
