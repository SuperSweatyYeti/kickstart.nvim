return {
  'epwalsh/obsidian.nvim',
  enabled = true,
  version = '*',
  lazy = true,
  ft = 'markdown',
  event = {
    -- Load on VimEnter if cwd is inside a vault directory
    'VimEnter',
  },
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
  },

  opts = function()
    local function is_dir(p)
      if not p or p == '' then
        return false
      end
      p = vim.fn.expand(p)
      return vim.fn.isdirectory(vim.fn.expand(p)) == 1
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
      -- NOTE: Unresolved vault notifications moved to config() to avoid
      -- triggering inside neo-tree/telescope buffer autocommands
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
      mappings = {
        ['<CR>'] = {
          action = function()
            return require('obsidian.util').smart_action()
          end,
          opts = { noremap = false, expr = true, buffer = true, desc = 'Obsidian smart action' },
        },
      },
    }
  end,

  config = function(_, opts)
    -- Only fully initialize if cwd is inside a vault, or a markdown file triggered load
    local cwd = vim.fs.normalize(vim.fn.getcwd())
    local in_vault = false
    for _, ws in ipairs(opts.workspaces) do
      local vault_path = vim.fs.normalize(ws.path)
      if cwd == vault_path or cwd:sub(1, #vault_path + 1) == vault_path .. '/' then
        in_vault = true
        break
      end
    end

    -- If loaded via VimEnter but not in a vault, bail out silently
    if not in_vault and vim.bo.filetype ~= 'markdown' then
      return
    end

    require('obsidian').setup(opts)

    -- Notify about unresolved vaults here, safely outside autocommand context
    local resolved_names = {}
    for _, ws in ipairs(opts.workspaces) do
      resolved_names[ws.name] = true
    end
    local all_vault_names = { 'Obsidian Vault', 'AACI', 'Work', 'Other' }
    for _, name in ipairs(all_vault_names) do
      if not resolved_names[name] then
        vim.notify("Obsidian.nvim: Path not resolved for vault '" .. name .. "'", vim.log.levels.DEBUG)
      end
    end

    -- Month names for folder: "1-January", "2-February", etc.
    local month_names = {
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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
      local now = os.date '*t'
      local year = tostring(now.year)
      local month_num = now.month
      local day_num = now.day

      local month_folder = month_num .. '-' .. month_names[month_num]
      local filename = month_num .. '-' .. day_num .. '-' .. year .. '.md'

      local vault_root = get_vault_root()
      local dir = vault_root .. '/Daily Notes/' .. year .. '/' .. month_folder
      local filepath = dir .. '/' .. filename

      -- Normalize for comparison
      local target = vim.fs.normalize(filepath)
      local current = vim.fs.normalize(vim.api.nvim_buf_get_name(0))

      -- Already viewing this file — just notify, don't re-open
      if current == target then
        vim.notify("Already in today's daily note", vim.log.levels.INFO)
        return
      end

      -- Create directories if they don't exist
      vim.fn.mkdir(dir, 'p')

      -- Open the file (creates it if new)
      vim.cmd('edit ' .. vim.fn.fnameescape(filepath))

      -- If the file is brand new (empty buffer), insert a template
      if vim.api.nvim_buf_line_count(0) <= 1 and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == '' then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
          -- header, -- optional Header
          '',
          '',
        })
        vim.api.nvim_win_set_cursor(0, { 2, 0 })
      end
    end

    vim.api.nvim_create_user_command('ObsidianDailyNote', open_daily_note, {
      desc = "Open or create today's daily note (Daily Notes/YYYY/M-Month/M-D-YYYY.md)",
    })
    require('which-key').add {
      { mode = { 'n' }, { '<leader>o', group = '[o]opencode/[o]bsidian', hidden = false } },
      { mode = { 'n' }, { '<leader>ob', group = '[o][b]sidian', hidden = false } },
    }
    -- Daily Note Keymap
    vim.keymap.set('n', '<leader>obd', '<cmd>ObsidianDailyNote<cr>', { desc = 'Obsidian Daily Note' })
    -- Other Keymaps
    vim.keymap.set('n', '<leader>obs', ':ObsidianSearch ', { desc = 'Obsidian Search' })
    vim.keymap.set('n', '<leader>obpi', ':ObsidianPasteImg ', { desc = 'Obsidian Paste Image' })
    vim.keymap.set('n', '<leader>obl', '<cmd>ObsidianLinks<cr>', { desc = 'Obsidian Links List' })
    vim.keymap.set('n', '<leader>obT', '<cmd>ObsidianTags<cr>', { desc = 'Obsidian Tags List' })
    vim.keymap.set('n', '<leader>obt', '<cmd>ObsidianToggleCheckbox<cr>', { desc = 'Obsidian Toggle Checkbox' })
  end,
}
