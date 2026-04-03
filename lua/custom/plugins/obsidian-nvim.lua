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

    ---Pick the first existing path from an OS-specific candidate table.
    ---Return nil if none exist.
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

    -- Define your vaults here.
    -- Fill in paths for each OS. First existing wins. If none exist -> nil.
    local vaults = {
      {
        name = 'Obsidian Vault', -- Personal Vault
        path = pick_path {
          windows = {
            -- "C:/Users/<you>/Documents/Obsidian-Vaults/Obsidian Vault",
            '~/Documents/Obsidian Vaults/Obsidian Vault',
          },
          darwin = {
            '~/Documents/Obsidian-Vaults/Obsidian Vault',
            -- "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault",
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
            -- "C:/Users/<you>/Documents/Obsidian-Vaults/Obsidian Vault",
            'D:\\Obsidian\\Vaults\\AACI\\AACI', -- AACI Laptop vault location
            '~/Documents/Obsidian Vaults/AACI',
          },
          darwin = {
            '~/Documents/Obsidian-Vaults/AACI',
            -- "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault",
          },
          linux = {
            '~/Documents/Obsidian-Vaults/AACI',
          },
        },
      },
      {
        name = 'Work',
        path = pick_path {
          windows = {
            -- "C:/Users/<you>/Documents/vaults/work",
          },
          darwin = {
            -- "~/vaults/work",
          },
          linux = {
            -- "~/vaults/work",
          },
        },
      },
      {
        name = 'Other',
        path = pick_path {
          windows = {
            -- "C:/Users/<you>/Documents/vaults/personal",
          },
          darwin = {
            -- "~/vaults/personal",
          },
          linux = {
            -- "~/vaults/personal",
          },
        },
      },
    }

    -- Keep only vaults that were found on this machine.
    local workspaces = {}
    for _, v in ipairs(vaults) do
      if v.path ~= nil then
        table.insert(workspaces, { name = v.name, path = v.path })
      end
    end

    return {
      disable_frontmatter = true,
      workspaces = workspaces, -- if none found, this will be {}
      obsidian_server_address = 'https://127.0.0.1:27124',
      cert_path = '~/.ssl/obsidian.crt',
      ui = {
        enable = false, -- disable to get rid of conceallevel warning
        -- We are using a different Plugin for markdown rendering anyways
        update_debounce = 200,
        max_file_length = 5000,
        checkboxes = {
          [' '] = { char = '󰄱', hl_group = 'ObsidianTodo' },
          ['x'] = { char = '', hl_group = 'ObsidianDone' },
        },
      },
    }
  end,

  -- Keymaps (your existing style)
  vim.keymap.set('n', '<leader>obs', ':ObsidianSearch ', { desc = 'Obsidian Search' }),
  vim.keymap.set('n', '<leader>obpi', ':ObsidianPasteImg ', { desc = 'Obsidian Paste Image' }),
  vim.keymap.set('n', '<leader>obl', '<cmd>ObsidianLinks<cr>', { desc = 'Obsidian Links List' }),
  vim.keymap.set('n', '<leader>obT', '<cmd>ObsidianTags<cr>', { desc = 'Obsidian Tags List' }),
  vim.keymap.set('n', '<leader>obt', '<cmd>ObsidianToggleCheckbox<cr>', { desc = 'Obsidian Toggle Checkbox' }),
}
