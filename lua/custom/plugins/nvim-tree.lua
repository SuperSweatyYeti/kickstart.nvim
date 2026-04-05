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
      self.enabled = true
      self.highlight_range = 'none'
      self.icon_placement = 'right_align'

      self.file_icon = {
        str = '●',
        hl = { 'NvimTreeModifiedIcon' },
      }

      self.folder_icon = {
        str = '…',
        hl = { 'NvimTreeModifiedFolderIcon' },
      }
    end

    ---@param node nvim_tree.api.Node
    ---@return nvim_tree.api.highlighted_string[]? icons
    function ModifiedChildDecorator:icons(node)
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
      unstaged = '~',
      staged = '+',
      untracked = '?',
      renamed = '»',
      deleted = 'X',
      unmerged = '',
      ignored = '',
    }

    local git_icon_colors = {
      NvimTreeGitDirtyIcon = { fg = '#e0af68' },
      NvimTreeGitStagedIcon = { fg = '#9ece6a' },
      NvimTreeGitNewIcon = { fg = '#7dcfff' },
      NvimTreeGitRenamedIcon = { fg = '#bb9af7' },
      NvimTreeGitDeletedIcon = { fg = '#f7768e' },
      NvimTreeGitMergeIcon = { fg = '#f7768e' },
      NvimTreeGitIgnoredIcon = { fg = '#545c7e' },
    }

    local git_name_colors = {
      NvimTreeGitDirtyHL = { fg = '#e0af68' },
      NvimTreeGitStagedHL = { fg = '#9ece6a' },
      NvimTreeGitNewHL = { fg = '#7dcfff' },
      NvimTreeGitRenamedHL = { fg = '#bb9af7' },
      NvimTreeGitDeletedHL = { fg = '#f7768e' },
      NvimTreeGitMergeHL = { fg = '#f7768e' },
      NvimTreeGitIgnoredHL = { fg = '#545c7e', italic = true },
    }

    local opened_file_color = '#ff9e64'

    for group, hl in pairs(git_icon_colors) do
      vim.api.nvim_set_hl(0, group, hl)
    end
    for group, hl in pairs(git_name_colors) do
      vim.api.nvim_set_hl(0, group, hl)
    end
    vim.api.nvim_set_hl(0, 'NvimTreeOpenedFile', { fg = opened_file_color, bold = true })
    vim.api.nvim_set_hl(0, 'NvimTreeModifiedIcon', { fg = '#ff9e64' })
    vim.api.nvim_set_hl(0, 'NvimTreeModifiedHL', { fg = '#ff9e64' })
    vim.api.nvim_set_hl(0, 'NvimTreeModifiedFolderIcon', { fg = '#7aa2f7' })

    -- ─────────────────────────────────────────────────────────
    -- Helpers: telescope pickers that reveal in tree
    -- ────────────────────────────────────────────────────────

    -- Find directories → expand to folder in tree, cursor on it
    local function telescope_find_dirs()
      local entry_display = require 'telescope.pickers.entry_display'
      local pickers = require 'telescope.pickers'
      local finders = require 'telescope.finders'
      local previewers = require 'telescope.previewers'
      local from_entry = require 'telescope.from_entry'
      local conf = require('telescope.config').values
      local utils = require 'telescope.utils'
      local Path = require 'plenary.path'
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      local cwd = vim.uv.cwd()

      local displayer = entry_display.create {
        separator = ' ',
        items = { { width = 2 }, { remaining = true } },
      }

      local lookup_keys = { ordinal = 1, value = 1, filename = 1, cwd = 2 }

      local mt_dir_entry = {}
      mt_dir_entry.cwd = cwd

      mt_dir_entry.display = function(entry)
        local text = utils.transform_path({}, entry.value)
        return displayer {
          { '', 'Directory' },
          { text, 'TelescopeResultsNormal' },
        }
      end

      mt_dir_entry.__index = function(t, k)
        local raw = rawget(mt_dir_entry, k)
        if raw then
          return raw
        end
        if k == 'path' then
          local retpath = Path:new({ t.cwd, t.value }):absolute()
          if not vim.uv.fs_access(retpath, 'R') then
            retpath = t.value
          end
          return retpath
        end
        return rawget(t, rawget(lookup_keys, k))
      end

      local dir_previewer = previewers.new_buffer_previewer {
        title = 'Directory Preview',
        define_preview = function(self, entry)
          local p = from_entry.path(entry, true, false)
          if p == nil or p == '' then
            return
          end
          local expanded = utils.path_expand(p)
          require('plenary.scandir').scan_dir_async(expanded, {
            hidden = true,
            depth = 1,
            add_dirs = true,
            on_exit = vim.schedule_wrap(function(results)
              if not vim.api.nvim_buf_is_valid(self.state.bufnr) then
                return
              end
              local lines, hl_lines = {}, {}
              for _, item in ipairs(results) do
                local name = vim.fn.fnamemodify(item, ':t')
                local stat = vim.uv.fs_stat(item)
                if stat and stat.type == 'directory' then
                  table.insert(lines, '' .. name)
                  table.insert(hl_lines, 'Directory')
                else
                  table.insert(lines, ' ' .. name)
                  table.insert(hl_lines, 'TelescopePreviewNormal')
                end
              end
              vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
              local ns = vim.api.nvim_create_namespace 'dir_preview'
              for i, hl_group in ipairs(hl_lines) do
                vim.hl.range(self.state.bufnr, ns, hl_group, { i - 1, 0 }, { i - 1, #lines[i] })
              end
            end),
          })
        end,
      }

      pickers
        .new({}, {
          prompt_title = 'Find Directories',
          finder = finders.new_oneshot_job({ 'fd', '--type', 'd' }, {
            entry_maker = function(line)
              return setmetatable({ line, cwd }, mt_dir_entry)
            end,
          }),
          previewer = dir_previewer,
          sorter = conf.generic_sorter {},
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local entry = action_state.get_selected_entry()
              local dir = Path:new({ cwd, entry.value }):absolute()

              -- open tree if not visible, then reveal and focus the folder
              if not nvim_tree_api.tree.is_visible() then
                nvim_tree_api.tree.open()
              end
              nvim_tree_api.tree.find_file { buf = dir, open = true, focus = true }
            end)
            return true
          end,
        })
        :find()
    end

    -- Find files → expand folders in tree and put cursor on the file
    local function telescope_find_files_reveal()
      local builtin = require 'telescope.builtin'
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      builtin.find_files {
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local entry = action_state.get_selected_entry()
            if not entry then
              return
            end

            local filepath = entry.path or entry.filename
            if not filepath then
              return
            end

            -- reveal in tree, expand folders, put cursor on file
            nvim_tree_api.tree.find_file { buf = filepath, open = true, focus = true }
          end)
          return true
        end,
      }
    end
    -- ─────────────────────────────────────────────────────────
    -- Keymaps (inside the tree buffer)
    -- ─────────────────────────────────────────────────────────
    local function on_attach(bufnr)
      local api = require 'nvim-tree.api'

      local function opts(desc)
        return {
          desc = 'nvim-tree: ' .. desc,
          buffer = bufnr,
          noremap = true,
          silent = true,
          nowait = true,
        }
      end

      require('which-key').add {
        { mode = { 'n' }, { '<leader>f', group = '[f]ile explorer tree', hidden = false } },
      }

      api.map.on_attach.default(bufnr)

      vim.keymap.set('n', '.', function()
        local node = api.tree.get_node_under_cursor()
        if node then
          local path = node.type == 'directory' and node.absolute_path or vim.fn.fnamemodify(node.absolute_path, ':h')
          api.tree.change_root(path)
          vim.cmd('cd ' .. vim.fn.fnameescape(path))
        end
      end, opts 'Set root & cd')

      vim.keymap.set('n', '-', api.tree.change_root_to_parent, opts 'Up')
      vim.keymap.set('n', 'u', api.tree.change_root_to_parent, opts 'Up')

      vim.keymap.set('n', 'f', api.filter.live.start, opts 'Live Filter: Start')
      vim.keymap.set('n', 'F', api.filter.live.clear, opts 'Live Filter: Clear')

      vim.keymap.set('n', 'v', api.node.open.vertical, opts 'Open: Vertical Split')
      vim.keymap.set('n', 's', api.node.open.horizontal, opts 'Open: Horizontal Split')

      vim.keymap.set('n', '?', api.tree.toggle_help, opts 'Help')
      vim.keymap.set('n', 'R', api.tree.reload, opts 'Refresh')
      vim.keymap.set('n', 'm', api.fs.rename, opts 'Rename')

      -- Telescope pickers that reveal back in tree
      vim.keymap.set('n', '<leader>sD', telescope_find_dirs, { buffer = bufnr, desc = '[s]earch [D]irectories (reveal in tree)' })
      vim.keymap.set('n', '<leader>sf', telescope_find_files_reveal, { buffer = bufnr, desc = '[s]earch [f]iles (reveal in tree)' })
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
          'Git',
          'Open',
          'Hidden',
          ModifiedChildDecorator,
          'Bookmark',
          'Diagnostics',
          'Copied',
          'Cut',
        },

        indent_markers = {
          enable = true,
          inline_arrows = false,
          icons = {
            corner = '└',
            edge = '│',
            item = '├',
            bottom = '─',
            none = ' ',
          },
        },

        icons = {
          git_placement = 'right_align',
          modified_placement = 'right_align',
          show = {
            git = true,
            file = true,
            folder = true,
            folder_arrow = false,
            modified = false, -- handled by our custom decorator
          },
          glyphs = {
            modified = '[+]',
            git = git_icons,
          },
        },
      },

      modified = {
        enable = true,
        show_on_dirs = true,
        show_on_open_dirs = true,
      },

      git = {
        enable = true,
        ignore = false,
        show_on_dirs = true,
        show_on_open_dirs = true,
      },

      filters = {
        dotfiles = false,
      },
    }

    -- ─────────────────────────────────────────────────────────
    -- Global keymaps (outside the tree buffer)
    -- ─────────────────────────────────────────────────────────
    vim.keymap.set('n', '<leader>fe', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle file explorer' })
    vim.keymap.set('n', '<leader>ef', '<cmd>NvimTreeFocus<CR>', { desc = 'Focus file explorer' })
    vim.keymap.set('n', '<leader>er', '<cmd>NvimTreeRefresh<CR>', { desc = 'Refresh file explorer' })
  end,
}
