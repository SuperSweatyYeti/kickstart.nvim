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
    local nvim_tree_api = require('nvim-tree.api')
    local buffers = require('nvim-tree.buffers')

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
    -- Custom Opened/Visible Buffer Decorator
    -- Bold white for opened buffers, bold orange for the visible one
    -- Replaces the built-in 'Open' decorator
    -- ─────────────────────────────────────────────────────────

    ---@class (exact) OpenedBufferDecorator: nvim_tree.api.Decorator
    local OpenedBufferDecorator = nvim_tree_api.Decorator:extend()

    vim.g.nvim_tree_visible_file = nil

    function OpenedBufferDecorator:new()
      self.enabled = true
      self.highlight_range = 'name'
      self.icon_placement = 'none'
    end

    ---@param node nvim_tree.api.Node
    ---@return string? highlight_group
    function OpenedBufferDecorator:highlight_group(node)
      if node.type == 'directory' then
        return nil
      end

      local visible = vim.g.nvim_tree_visible_file
      if visible and vim.fs.normalize(node.absolute_path) == visible then
        return 'NvimTreeVisibleFile'
      end

      -- Check if this file has a loaded buffer
      if vim.fn.bufloaded(node.absolute_path) > 0 then
        return 'NvimTreeOpenedFile'
      end

      return nil
    end

    -- Update the visible file tracker whenever you enter a buffer
    vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
      callback = function()
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname ~= '' and vim.bo.buftype == '' then
          vim.g.nvim_tree_visible_file = vim.fs.normalize(bufname)
          if nvim_tree_api.tree.is_visible() then
            nvim_tree_api.tree.reload()
          end
        end
      end,
    })

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
    -- Opened files (any buffer that's loaded) → bold bright white
    vim.api.nvim_set_hl(0, 'NvimTreeOpenedFile', { fg = '#ffffff', bold = true })
    -- Visible/active buffer → orange
    vim.api.nvim_set_hl(0, 'NvimTreeVisibleFile', { fg = opened_file_color, bold = true })

    vim.api.nvim_set_hl(0, 'NvimTreeModifiedIcon', { fg = '#ff9e64' })
    vim.api.nvim_set_hl(0, 'NvimTreeModifiedHL', { fg = '#ff9e64' })
    vim.api.nvim_set_hl(0, 'NvimTreeModifiedFolderIcon', { fg = '#7aa2f7' })

    -- ─────────────────────────────────────────────────────────
    -- Helpers: telescope pickers that reveal in tree
    -- ────────────────────────────────────────────────────────

    -- Find directories → expand to folder in tree, cursor on it
    local function telescope_find_dirs()
      local entry_display = require('telescope.pickers.entry_display')
      local pickers = require('telescope.pickers')
      local finders = require('telescope.finders')
      local previewers = require('telescope.previewers')
      local from_entry = require('telescope.from_entry')
      local conf = require('telescope.config').values
      local utils = require('telescope.utils')
      local Path = require('plenary.path')
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')

      local cwd = vim.uv.cwd()

      local displayer = entry_display.create({
        separator = ' ',
        items = { { width = 2 }, { remaining = true } },
      })

      local lookup_keys = { ordinal = 1, value = 1, filename = 1, cwd = 2 }

      local mt_dir_entry = {}
      mt_dir_entry.cwd = cwd

      mt_dir_entry.display = function(entry)
        local text = utils.transform_path({}, entry.value)
        return displayer({
          { '', 'Directory' },
          { text, 'TelescopeResultsNormal' },
        })
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

      local dir_previewer = previewers.new_buffer_previewer({
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
              local ns = vim.api.nvim_create_namespace('dir_preview')
              for i, hl_group in ipairs(hl_lines) do
                vim.hl.range(self.state.bufnr, ns, hl_group, { i - 1, 0 }, { i - 1, #lines[i] })
              end
            end),
          })
        end,
      })

      pickers
        .new({}, {
          prompt_title = 'Find Directories',
          finder = finders.new_oneshot_job({ 'fd', '--type', 'd' }, {
            entry_maker = function(line)
              return setmetatable({ line, cwd }, mt_dir_entry)
            end,
          }),
          previewer = dir_previewer,
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local entry = action_state.get_selected_entry()
              local dir = Path:new({ cwd, entry.value }):absolute()

              -- open tree if not visible, then reveal and focus the folder
              if not nvim_tree_api.tree.is_visible() then
                nvim_tree_api.tree.open()
              end
              nvim_tree_api.tree.find_file({ buf = dir, open = true, focus = true })
            end)
            return true
          end,
        })
        :find()
    end

    -- Find files → expand folders in tree and put cursor on the file
    local function telescope_find_files_reveal()
      local builtin = require('telescope.builtin')
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')

      builtin.find_files({
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
            nvim_tree_api.tree.find_file({ buf = filepath, open = true, focus = true })
          end)
          return true
        end,
      })
    end
    -- ─────────────────────────────────────────────────────────
    -- Keymaps (inside the tree buffer)
    -- ─────────────────────────────────────────────────────────

    require('which-key').add({
      { mode = { 'n' }, { '<leader>f', group = '[f]ile explorer tree', hidden = false } },
    })
    local function on_attach(bufnr)
      -- Sticky root folder: show current root in winbar so it's always visible
      -- Only targets windows displaying the nvim-tree buffer
      local function update_winbar()
        local tree_api = require('nvim-tree.api')
        local root = tree_api.tree.get_nodes()
        if root and root.absolute_path then
          local root_name = vim.fn.fnamemodify(root.absolute_path, ':~')
          local winbar_str = '%#NvimTreeWinbar#  ' .. root_name .. '%*'
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == bufnr then
              vim.api.nvim_set_option_value('winbar', winbar_str, { win = win })
            end
          end
        end
      end

      update_winbar()

      vim.api.nvim_create_autocmd({ 'BufEnter', 'DirChanged' }, {
        buffer = bufnr,
        callback = update_winbar,
      })

      -- Also update winbar after root changes via nvim-tree events
      nvim_tree_api.events.subscribe(nvim_tree_api.events.Event.TreeRendered, function()
        update_winbar()
      end)

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

      -- Remove keymap for filepath only need folderpath
      -- When inside nvim-tree: remove file path keymaps (no file buffer active),
      -- keep only folder keymaps. Restore file keymaps on leave.
      vim.api.nvim_create_autocmd('BufEnter', {
        buffer = bufnr,
        callback = function()
          pcall(vim.keymap.del, 'n', '<leader>pwbfo')
          pcall(vim.keymap.del, 'n', '<leader>pwbfc')
        end,
      })

      vim.api.nvim_create_autocmd('BufLeave', {
        buffer = bufnr,
        callback = function()
          vim.keymap.set('n', '<leader>pwbfo', function()
            print(vim.fn.expand('%:p'))
          end, { desc = '[p]rint [w]orking [b]uffer [f]ilepath [o]utput' })

          vim.keymap.set('n', '<leader>pwbfc', function()
            vim.fn.setreg('+', vim.fn.expand('%:p'))
          end, { desc = '[p]rint [w]orking [b]uffer [f]ilepath to [c]lipboard' })
        end,
      })

      require('which-key').add({
        { mode = { 'n' }, { '<leader>f', group = '[f]ile explorer tree', hidden = false } },
      })

      api.map.on_attach.default(bufnr)

      vim.keymap.set('n', '.', function()
        local node = api.tree.get_node_under_cursor()
        if node then
          local path = node.type == 'directory' and node.absolute_path or vim.fn.fnamemodify(node.absolute_path, ':h')
          api.tree.change_root(path)
          vim.cmd('cd ' .. vim.fn.fnameescape(path))
        end
      end, opts('Set root & cd'))

      -- Move cursor up to nearest Parent Folder
      vim.keymap.set('n', 'P', function()
        local node = api.tree.get_node_under_cursor()
        if node and node.parent then
          api.tree.find_file({ buf = node.parent.absolute_path, open = true, focus = true })
        end
      end, opts('Go to parent folder'))

      -- Remove default keymap of 'e' to edit filename
      vim.keymap.del('n', 'e', { buffer = bufnr })

      -- Move cursor down to nearest expanded sub-folder
      vim.keymap.set('n', 'p', function()
        local node = api.tree.get_node_under_cursor()
        if not node then
          return
        end

        local start_line = vim.api.nvim_win_get_cursor(0)[1]
        local line_count = vim.api.nvim_buf_line_count(0)

        for i = start_line + 1, line_count do
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          local next_node = api.tree.get_node_under_cursor()
          if next_node and next_node.type == 'directory' and next_node.open then
            return
          end
        end

        -- No expanded directory found below, go back
        vim.api.nvim_win_set_cursor(0, { start_line, 0 })
      end, opts('Go to next expanded folder below'))

      -- When inside nvim-tree: remove file path keymaps (no file buffer active),
      -- keep only folder keymaps. Restore file keymaps on leave.
      vim.api.nvim_create_autocmd('BufEnter', {
        buffer = bufnr,
        callback = function()
          pcall(vim.keymap.del, 'n', '<leader>pwbfo')
          pcall(vim.keymap.del, 'n', '<leader>pwbfc')
        end,
      })

      vim.api.nvim_create_autocmd('BufLeave', {
        buffer = bufnr,
        callback = function()
          vim.keymap.set('n', '<leader>pwbfo', function()
            print(vim.fn.expand('%:p'))
          end, { desc = '[p]rint [w]orking [b]uffer [f]ilepath [o]utput' })

          vim.keymap.set('n', '<leader>pwbfc', function()
            vim.fn.setreg('+', vim.fn.expand('%:p'))
          end, { desc = '[p]rint [w]orking [b]uffer [f]ilepath to [c]lipboard' })
        end,
      })

      vim.keymap.set('n', '-', api.tree.change_root_to_parent, opts('Up'))
      vim.keymap.set('n', 'u', api.tree.change_root_to_parent, opts('Up'))

      vim.keymap.set('n', 'f', api.filter.live.start, opts('Live Filter: Start'))
      vim.keymap.set('n', 'F', api.filter.live.clear, opts('Live Filter: Clear'))

      vim.keymap.set('n', 'v', api.node.open.vertical, opts('Open: Vertical Split'))
      vim.keymap.set('n', 's', api.node.open.horizontal, opts('Open: Horizontal Split'))

      vim.keymap.set('n', '?', api.tree.toggle_help, opts('Help'))

      -- Collapse all folders with "C"
      vim.keymap.set('n', 'C', api.tree.collapse_all, opts('Collapse All Folders'))
      vim.keymap.set('n', 'R', api.tree.reload, opts('Refresh'))
      vim.keymap.set('n', 'm', api.fs.rename, opts('Rename'))
      -- Telescope pickers that reveal back in tree
      vim.keymap.set('n', '<leader>sD', telescope_find_dirs, { buffer = bufnr, desc = '[s]earch [D]irectories (reveal in tree)' })
      vim.keymap.set('n', '<leader>sf', telescope_find_files_reveal, { buffer = bufnr, desc = '[s]earch [f]iles (reveal in tree)' })
    end

    -- Other Keymaps even without attach
    vim.keymap.set('n', '<leader>fF', function()
      require('nvim-tree.api').tree.find_file({ open = true, focus = true })
    end, { desc = 'Find File in NvimTree' })

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
        root_folder_label = false,
        indent_width = 2,
        highlight_opened_files = 'none',
        highlight_git = 'name',

        decorators = {
          'Git',
          OpenedBufferDecorator,
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
    })

    -- Inherit folder color for the sticky winbar root label
    local folder_hl = vim.api.nvim_get_hl(0, { name = 'NvimTreeFolderName', link = false })
    vim.api.nvim_set_hl(0, 'NvimTreeWinbar', vim.tbl_extend('force', folder_hl, { bold = true, italic = true }))

    -- ─────────────────────────────────────────────────────────
    -- Global keymaps (outside the tree buffer)
    -- ─────────────────────────────────────────────────────────
    vim.keymap.set('n', '<leader>fe', '<cmd>NvimTreeToggle<CR>', { desc = 'Toggle file explorer' })
    vim.keymap.set('n', '<leader>ef', '<cmd>NvimTreeFocus<CR>', { desc = 'Focus file explorer' })
    vim.keymap.set('n', '<leader>er', '<cmd>NvimTreeRefresh<CR>', { desc = 'Refresh file explorer' })
  end,
}
