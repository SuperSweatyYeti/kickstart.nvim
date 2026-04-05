return {
  'nvim-tree/nvim-tree.lua',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- ─────────────────────────────────────────────────────────
    -- Git signs & colors — edit these to your liking
    -- ─────────────────────────────────────────────────────────
    local git_icons = {
      unstaged  = '~',
      staged    = '+',
      untracked = '?',
      renamed   = '»',
      deleted   = 'X',
      unmerged  = '',
      ignored   = '',
    }

    -- Icon highlight groups (the glyph itself)
    local git_icon_colors = {
      NvimTreeGitDirtyIcon   = { fg = '#e0af68' }, -- unstaged   → yellow
      NvimTreeGitStagedIcon  = { fg = '#9ece6a' }, -- staged     → green
      NvimTreeGitNewIcon     = { fg = '#7dcfff' }, -- untracked  → blue
      NvimTreeGitRenamedIcon = { fg = '#bb9af7' }, -- renamed    → purple
      NvimTreeGitDeletedIcon = { fg = '#f7768e' }, -- deleted    → red
      NvimTreeGitMergeIcon   = { fg = '#f7768e' }, -- unmerged   → red
      NvimTreeGitIgnoredIcon = { fg = '#545c7e' }, -- ignored    → muted
    }

    -- File name highlight groups (the filename text)
    local git_name_colors = {
      NvimTreeGitDirtyHL   = { fg = '#e0af68' },
      NvimTreeGitStagedHL  = { fg = '#9ece6a' },
      NvimTreeGitNewHL     = { fg = '#7dcfff' },
      NvimTreeGitRenamedHL = { fg = '#bb9af7' },
      NvimTreeGitDeletedHL = { fg = '#f7768e' },
      NvimTreeGitMergeHL   = { fg = '#f7768e' },
      NvimTreeGitIgnoredHL = { fg = '#545c7e', italic = true },
    }

    -- Active/opened file — edit sign color here
    local opened_file_color = '#ff9e64' -- orange

    for group, hl in pairs(git_icon_colors) do
      vim.api.nvim_set_hl(0, group, hl)
    end
    for group, hl in pairs(git_name_colors) do
      vim.api.nvim_set_hl(0, group, hl)
    end
    vim.api.nvim_set_hl(0, 'NvimTreeOpenedFile', { fg = opened_file_color, bold = true })
    -- Modified icon color
    vim.api.nvim_set_hl(0, 'NvimTreeModifiedIcon', { fg = '#ff9e64' }) -- the ● glyph
    vim.api.nvim_set_hl(0, 'NvimTreeModifiedHL',   { fg = '#ff9e64' }) -- the filename text

    -- ─────────────────────────────────────────────────────────
    -- Keymaps (inside the tree buffer)
    -- ─────────────────────────────────────────────────────────
    local function on_attach(bufnr)
      local api = require('nvim-tree.api')

      local function opts(desc)
        return {
          desc = 'nvim-tree: ' .. desc,
          buffer = bufnr,
          noremap = true,
          silent = true,
          nowait = true,
        }
      end

      -- Load all defaults first, then override/add
      api.map.on_attach.default(bufnr)

      -- "." → set as new root AND cd into it
      vim.keymap.set('n', '.', function()
        local node = api.tree.get_node_under_cursor()
        if node then
          local path = node.type == 'directory' and node.absolute_path
            or vim.fn.fnamemodify(node.absolute_path, ':h')
          api.tree.change_root(path)
          vim.cmd('cd ' .. vim.fn.fnameescape(path))
        end
      end, opts('Set root & cd'))

      vim.keymap.set('n', '-', api.tree.change_root_to_parent, opts('Up'))
      vim.keymap.set('n', 'u', api.tree.change_root_to_parent, opts('Up'))

      vim.keymap.set('n', 'f', api.filter.live.start, opts('Live Filter: Start'))
      vim.keymap.set('n', 'F', api.filter.live.clear, opts('Live Filter: Clear'))

      vim.keymap.set('n', 'v', api.node.open.vertical,   opts('Open: Vertical Split'))
      vim.keymap.set('n', 's', api.node.open.horizontal, opts('Open: Horizontal Split'))

      vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))
      vim.keymap.set('n', 'R', api.tree.reload,      opts('Refresh'))
      -- Move (rename)
      vim.keymap.set('n', 'm', api.fs.rename, opts('Rename'))
    end

    -- ─────────────────────────────────────────────────────────
    -- Setup
    -- ─────────────────────────────────────────────────────────
    require('nvim-tree').setup({
      on_attach = on_attach,

      live_filter = {
        prefix = '> ',
        always_show_folders = false,
      },

      view = {
        width = 40,
        side = 'left',
        signcolumn = 'yes',
      },

      renderer = {
        indent_width = 2,
        highlight_opened_files = 'name', -- 'icon', 'name', or 'all'
        highlight_git = 'name',

        indent_markers = {
          enable = true,
          inline_arrows = false,
          icons = {
            corner = '└',
            edge   = '│',
            item   = '├',
            bottom = '─',
            none   = ' ',
          },
        },

        icons = {
          git_placement      = 'right_align',
          modified_placement = 'right_align',
          show = {
            git          = true,
            file         = true,
            folder       = true,
            folder_arrow = false,
            modified     = true,
          },
          glyphs = {
            modified = '●', -- ← correct level: glyphs, not glyphs.git
            git = git_icons,
          },
        },
      },
      modified = {
        enable = true,
      },
      git = {
        enable            = true,
        ignore            = false,
        show_on_dirs      = true,
        show_on_open_dirs = true,
      },

      filters = {
        dotfiles = false,
      },
    })

    -- Global keymaps (outside the tree buffer)
    vim.keymap.set('n', '<leader>fe',  '<cmd>NvimTreeToggle<CR>',  { desc = 'Toggle file explorer' })
    vim.keymap.set('n', '<leader>ef', '<cmd>NvimTreeFocus<CR>',   { desc = 'Focus file explorer' })
    vim.keymap.set('n', '<leader>er', '<cmd>NvimTreeRefresh<CR>', { desc = 'Refresh file explorer' })
  end,
}
