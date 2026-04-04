vim.api.nvim_create_user_command('Messages', function()
  local messages = vim.fn.execute 'messages'
  local height = math.floor(vim.o.lines / 3)
  vim.cmd('botright ' .. height .. 'new')
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
  vim.bo.readonly = true
  vim.bo.modifiable = true
  local lines = vim.split(messages, '\n')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.modifiable = false
end, { desc = 'Open :messages in a readonly buffer' })

-- vim.cmd [[cabbrev messages Messages]] -- Optionally alias messages to Messages
