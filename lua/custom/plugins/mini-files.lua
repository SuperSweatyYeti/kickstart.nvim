return {
  'echasnovski/mini.files',
  enabled = false,
  version = '*', -- use stable release
  config = function()
    require('mini.files').setup({
      -- File content options
      content = {
        filter = nil,   -- show all files (set a function to filter)
        sort = nil,     -- default sorting
      },

      -- Window appearance
      windows = {
        max_number = 3,       -- max number of column windows
        preview = true,       -- show preview of file/directory
        width_focus = 50,     -- width of focused window
        width_nofocus = 15,   -- width of non-focused windows
        width_preview = 50,   -- width of preview window
      },

      -- Options for the explorer itself
      options = {
        permanent_delete = false, -- move to trash instead of permanent delete
        use_as_default_explorer = true, -- replace netrw
      },
    })

    -- Keymaps
    vim.keymap.set('n', '<leader>e', function()
      require('mini.files').open()
    end, { desc = 'Open file explorer' })

    vim.keymap.set('n', '<leader>ef', function()
      -- Open at current file's directory
      require('mini.files').open(vim.api.nvim_buf_get_name(0))
    end, { desc = 'Open explorer at current file' })
  end,
}
