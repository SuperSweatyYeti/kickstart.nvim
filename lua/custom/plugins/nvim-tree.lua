return {
  'nvim-tree/nvim-tree.lua',
  enabled = true,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- ─────────────────────────────────────────────────────────
    -- Custom Modified Decorator
    -- [+] on modified files, … on folders with modified children
    -- ─────────────────────────────────────────────────────────
      local nvim_tree_api = require 'nvim-tree.api'
      local buffers = require 'nvim-tree.buffers'

      ---@class (exact) ModifiedChildDecorator: nvim_tree.api.Decorator
      ---@field private file_icon nvim_tree.api.highlighted_string
      ---@field private folder_icon nvim_tree.api.highlighted_string
      local ModifiedChildDecorator = nvim_tree_api.Decorator:extend()

      function ModifiedChildDecorator:new()
        self.enabled         = true
        self.highlight_range = 'none'
        self.icon_placement  = 'right_align'

        self.file_icon = {
          str = '●',
          hl  = { 'NvimTreeModifiedIcon' },
        }

        self.folder_icon = {
          str = '…',
          hl  = { 'NvimTreeModifiedFolderIcon' },
        }
      end

      ---@param node nvim_tree.api.Node
      ---@return nvim_tree.api.highlighted_string[]? icons
      function ModifiedChildDecorator:icons(node)
        -- use _modified directly — the public api.Node doesn't have :as() so
        -- we can't call buffers.is_modified(node) which needs an internal Node
        if not buffers._modified[node.absolute_path] then
          return nil
        end

        if node.type == 'directory' then
          return { self.folder_icon }
        else
          return { self.file_icon }
        end
      end
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

    local git_icon_colors = {
      NvimTreeGitDirtyIcon   = { fg = '#e0af68' },
      NvimTreeGitStagedIcon  = { fg = '#9ece6a' },
      NvimTreeGitNewIcon     = { fg = '#7dcfff' },
      NvimTreeGitRenamedIcon = { fg = '#bb9af7' },
      NvimTreeGitDeletedIcon = { fg = '#f7768e' },
      NvimTreeGitMergeIcon   = { fg = '#f7768e' },
      NvimTreeGitIgnoredIcon = { fg = '#545c7e' },
    }

    local git_name_colors = {
      NvimTreeGitDirtyHL   = { fg = '#e0af68' },
      NvimTreeGitStagedHL  = { fg = '#9ece6a' },
      NvimTreeGitNewHL     = { fg = '#7dcfff' },
      NvimTreeGitRenamedHL = { fg = '#bb9af7' },
      NvimTreeGitDeletedHL = { fg = '#f7768e' },
      NvimTreeGitMergeHL   = { fg = '#f7768e' },
      NvimTreeGitIgnoredHL = { fg = '#545c7e', italic = true },
    }

    local opened_file_color = '#ff9e64'

    for group, hl in pairs(git_icon_colors) do
      vim.api.nvim_set_hl(0, group, hl)
    end
    for group, hl in pairs(git_name_colors) do
      vim.api.nvim_set_hl(0, group, hl)
    end
    vim.api.nvim_set_hl(0, 'NvimTreeOpenedFile',        { fg = opened_file_color, bold = true })
    vim.api.nvim_set_hl(0, 'NvimTreeModifiedIcon',      { fg = '#ff9e64' }) -- ● on files
    vim.api.nvim_set_hl(0, 'NvimTreeModifiedHL',        { fg = '#ff9e64' }) -- filename text
    vim.api.nvim_set_hl(0, 'NvimTreeModifiedFolderIcon',{ fg = '#7aa2f7' }) -- … on folders

    -- ─────────────────────────────────────────────────────────
    -- Keymaps (inside the tree buffer)
    -- ────────────────────────────────────────────────────────
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

      api.map.on_attach.default(bufnr)

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
      vim.keymap.set('n', 'm', api.fs.rename,        opts('Rename'))
    end

    -- ─────────────────────────────────────────────────────────
    -- Setup
    -- ─────────────────────────────────────────────────────────
    require('nvim-tree').setup {
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
        highlight_opened_files = 'name',
        highlight_git = 'name',

        decorators = {
          'Git', 'Open', 'Hidden',
          ModifiedChildDecorator, -- replaces built-in "Modified"
          'Bookmark', 'Diagnostics', 'Copied', 'Cut',
        },

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
            modified     = false, -- handled by our custom decorator
          },
          glyphs = {
            modified = '[+]',
            git = git_icons,
          },
        },
      },

      modified = {
        enable = true,
        show_on_dirs = true,      -- needed so buffers.is_modified works on dirs
        show_on_open_dirs = true,
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
    }

    -- ─────────────────────────────────────────────────────────
    -- Global keymaps (outside the tree buffer)
    -- ─────────────────────────────────────────────────────────
    vim.keymap.set('n', '<leader>fe', '<cmd>NvimTreeToggle<CR>',  { desc = 'Toggle file explorer' })
    vim.keymap.set('n', '<leader>ef', '<cmd>NvimTreeFocus<CR>',   { desc = 'Focus file explorer' })
    vim.keymap.set('n', '<leader>er', '<cmd>NvimTreeRefresh<CR>', { desc = 'Refresh file explorer' })
  end,
}
