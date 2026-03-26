return {
  'epwalsh/obsidian.nvim',
  enabled = true,
  version = '*', -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = 'markdown',
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre path/to/my-vault/*.md",
  --   "BufNewFile path/to/my-vault/*.md",
  -- },
  dependencies = {
    -- Required.
    {
      'nvim-lua/plenary.nvim',
    },
    -- {
    --   'oflisback/obsidian-bridge.nvim',
    --   event = {
    --     'BufReadPre *.md',
    --     'BufNewFile *.md',
    --   },
    --   lazy = true,
    -- },
  },
  opts = {
    disable_frontmatter = true,
    workspaces = {
      {
        name = 'Obsidian Vault',
        path = '~/Documents/Obsidian-Vaults/Obsidian Vault',
      },
      -- {
      --   name = "work",
      --   path = "~/vaults/work",
      -- },
      -- your config here
    },
    obsidian_server_address = 'https://127.0.0.1:27124',
    cert_path = '~/.ssl/obsidian.crt',
    ui = {
      enable = true, -- set to false to disable all additional syntax features
      update_debounce = 200, -- update delay after a text change (in milliseconds)
      max_file_length = 5000, -- disable UI features for files with more than this many lines
      -- Define how various check-boxes are displayed
      checkboxes = {
        -- NOTE: the 'char' value has to be a single character, and the highlight groups are defined below.
        --
        -- NOTE: we only want to toggle between empty and 'x'
        [' '] = { char = '󰄱', hl_group = 'ObsidianTodo' },
        ['x'] = { char = '', hl_group = 'ObsidianDone' },
        -- ['>'] = { char = '', hl_group = 'ObsidianRightArrow' },
        -- ['~'] = { char = '󰰱', hl_group = 'ObsidianTilde' },
        -- ['!'] = { char = '', hl_group = 'ObsidianImportant' },
        -- Replace the above with this if you don't have a patched font:
        -- [" "] = { char = "☐", hl_group = "ObsidianTodo" },
        -- ["x"] = { char = "✔", hl_group = "ObsidianDone" },

        -- You can also add more custom ones...
      },
    },

    -- see below for full list of options 👇
  },
  -- Keymaps
  vim.keymap.set('n', '<leader>obs', ':ObsidianSearch ', { desc = 'Obsidian Search' }),
  vim.keymap.set('n', '<leader>obpi', ':ObsidianPasteImg ', { desc = 'Obsidian Paste Image' }),
  vim.keymap.set('n', '<leader>obl', '<cmd>ObsidianLinks<cr>', { desc = 'Obsidian Links List' }),
  vim.keymap.set('n', '<leader>obT', '<cmd>ObsidianTags<cr>', { desc = 'Obsidian Tags List' }),
  vim.keymap.set('n', '<leader>obt', '<cmd>ObsidianToggleCheckbox<cr>', { desc = 'Obsidian Toggle Checkbox' }),
}
