return {
  'epwalsh/obsidian.nvim',
  enabled = true,
  version = '*',
  lazy = true,
  ft = 'markdown',
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
  },

  opts = function()
    local function is_dir(p)
      if not p or p == '' then
        return false
      end
      p = vim.fn.expand(p)
      return vim.fn.isdirectory(p) == 1
    end

    ---@param per_os { windows?: string[], darwin?: string[], linux?: string[] }
    local function pick_path(per_os)
      local list
      if is_os_windows() then
        list = per_os.windows or {}
      elseif is_os_darwin() then
        list = per_os.darwin or {}
      else
        list = per_os.linux or {}
      end

      for _, p in ipairs(list) do
        if is_dir(p) then
          return vim.fn.expand(p)
        end
      end

      return nil
    end

    local vaults = {
      {
        name = 'Obsidian Vault',
        path = pick_path {
          windows = {
            '~/Documents/Obsidian Vaults/Obsidian Vault',
          },
          darwin = {
            '~/Documents/Obsidian-Vaults/Obsidian Vault',
          },
          linux = {
            '~/Documents/Obsidian-Vaults/Obsidian Vault',
          },
        },
      },
      {
        name = 'AACI',
        path = pick_path {
          windows = {
            'D:\\Obsidian\\Vaults\\AACI\\AACI',
            '~/Documents/Obsidian Vaults/AACI',
          },
          darwin = {
            '~/Documents/Obsidian-Vaults/AACI',
          },
          linux = {
            '~/Documents/Obsidian-Vaults/AACI',
          },
        },
      },
      {
        name = 'Work',
        path = pick_path {
          windows = {},
          darwin = {},
          linux = {},
        },
      },
      {
        name = 'Other',
        path = pick_path {
          windows = {},
          darwin = {},
          linux = {},
        },
      },
    }

    local workspaces = {}
    for _, v in ipairs(vaults) do
      if v.path ~= nil then
        table.insert(workspaces, { name = v.name, path = v.path })
      end
    end

    return {
      disable_frontmatter = true,
      workspaces = workspaces,
      obsidian_server_address = 'https://127.0.0.1:27124',
      cert_path = '~/.ssl/obsidian.crt',
      ui = {
        enable = false,
        update_debounce = 200,
        max_file_length = 5000,
        checkboxes = {
          [' '] = { char = '󰄱', hl_group = 'ObsidianTodo' },
          ['x'] = { char = '', hl_group = 'ObsidianDone' },
        },
      },
    }
  end,

  config = function(_, opts)
    require('obsidian').setup(opts)

    -- Month names for folder: "1-January", "2-February", etc.
    local month_names = {
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    }

    --- Get the vault root for the current workspace.
    --- Falls back to cwd if obsidian.nvim client isn't available.
    local function get_vault_root()
      local ok, client = pcall(function()
        return require('obsidian').get_client()
      end)
      if ok and client and client.dir then
        return tostring(client.dir)
      end
      return vim.fn.getcwd()
    end

    --- Build the daily note path and open/create it.
    --- Pattern: Daily-Notes/YYYY/M-MonthName/M-D-YYYY.md
    local function open_daily_note()
      local now = os.date('*t')
      local year = tostring(now.year)
      local month_num = now.month
      local day_num = now.day

      -- "1-January", "12-December"
      local month_folder = month_num .. '-' .. month_names[month_num]

      -- "1-5-2026.md"
      local filename = month_num .. '-' .. day_num .. '-' .. year .. '.md'

      local vault_root = get_vault_root()
      local dir = vault_root .. '/Daily Notes/' .. year .. '/' .. month_folder
      local filepath = dir .. '/' .. filename

      -- Create directories if they don't exist
      vim.fn.mkdir(dir, 'p')

      -- Open the file (creates it if new)
      vim.cmd('edit ' .. vim.fn.fnameescape(filepath))

      -- If the file is brand new (empty buffer), insert a template
      if vim.api.nvim_buf_line_count(0) <= 1 and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == '' then
        local header = '# ' .. month_names[month_num] .. ' ' .. day_num .. ', ' .. year
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
          -- header, -- optional Header
          '',
          '',
        })
        -- Place cursor on the second line at the end
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
      end
    end

    vim.api.nvim_create_user_command('ObsidianDailyNote', open_daily_note, {
      desc = 'Open or create today\'s daily note (Daily Notes/YYYY/M-Month/M-D-YYYY.md)',
    })

    vim.keymap.set('n', '<leader>obd', '<cmd>ObsidianDailyNote<cr>', { desc = 'Obsidian Daily Note' })
  end,

  -- Keymaps
  vim.keymap.set('n', '<leader>obs', ':ObsidianSearch ', { desc = 'Obsidian Search' }),
  vim.keymap.set('n', '<leader>obpi', ':ObsidianPasteImg ', { desc = 'Obsidian Paste Image' }),
  vim.keymap.set('n', '<leader>obl', '<cmd>ObsidianLinks<cr>', { desc = 'Obsidian Links List' }),
  vim.keymap.set('n', '<leader>obT', '<cmd>ObsidianTags<cr>', { desc = 'Obsidian Tags List' }),
  vim.keymap.set('n', '<leader>obt', '<cmd>ObsidianToggleCheckbox<cr>', { desc = 'Obsidian Toggle Checkbox' }),
}
