return {
  'nvim-neo-tree/neo-tree.nvim',
  enabled = true,
  branch = 'v3.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    -- ─────────────────────────────────────────────────────────
    -- Disable netrw (same as your nvim-tree config)
    -- ─────────────────────────────────────────────────────────

    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- ─────────────────────────────────────────────────────────
    -- Git icon & name highlight colors (Tokyo Night palette)
    -- ─────────────────────────────────────────────────────────
    local git_icon_colors = {
      NeoTreeGitModified = { fg = '#e0af68' },
      NeoTreeGitAdded = { fg = '#9ece6a' },
      NeoTreeGitUntracked = { fg = '#7dcfff' },
      NeoTreeGitRenamed = { fg = '#bb9af7' },
      NeoTreeGitDeleted = { fg = '#f7768e' },
      NeoTreeGitConflict = { fg = '#f7768e' },
      NeoTreeGitIgnored = { fg = '#545c7e' },
      NeoTreeGitUnstaged = { fg = '#e0af68' },
      NeoTreeGitStaged = { fg = '#9ece6a' },
    }

    for group, hl in pairs(git_icon_colors) do
      vim.api.nvim_set_hl(0, group, hl)
    end

    vim.api.nvim_set_hl(0, 'NeoTreeModified', { fg = '#ff9e64' })
    vim.api.nvim_set_hl(0, 'NeoTreeFileNameOpened', { fg = '#ffffff', bold = true })
    vim.api.nvim_set_hl(0, 'NeoTreeVisibleFile', { fg = '#ff9e64', bold = true })
    vim.api.nvim_set_hl(0, 'NeoTreeWinbar', { fg = '#7aa2f7', bold = true, italic = true })
    vim.api.nvim_set_hl(0, 'NeoTreeModifiedFolderIcon', { fg = '#7aa2f7' })

    -- ─────────────────────────────────────────────────────────
    -- Track the visible/active buffer for custom highlighting
    -- ─────────────────────────────────────────────────────────
    vim.g.neo_tree_visible_file = nil

    vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
      callback = function()
        local bufname = vim.api.nvim_buf_get_name(0)
        if bufname ~= '' and vim.bo.buftype == '' then
          vim.g.neo_tree_visible_file = vim.fs.normalize(bufname)
          pcall(function()
            require('neo-tree.sources.manager').refresh('filesystem')
          end)
        end
      end,
    })

    -- ─────────────────────────────────────────────────────────
    -- Helpers: telescope pickers that reveal in tree
    -- ─────────────────────────────────────────────────────────
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
                  table.insert(lines, ' ' .. name)
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

              require('neo-tree.command').execute({
                action = 'focus',
                source = 'filesystem',
                position = 'left',
                reveal_file = dir,
                reveal_force_cwd = true,
              })
            end)
            return true
          end,
        })
        :find()
    end

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

            require('neo-tree.command').execute({
              action = 'focus',
              source = 'filesystem',
              position = 'left',
              reveal_file = filepath,
              reveal_force_cwd = false,
            })
          end)
          return true
        end,
      })
    end

    local function telescope_find_files_hidden_reveal()
      local builtin = require('telescope.builtin')
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')

      builtin.find_files({
        prompt_title = 'Find Files (Include Hidden)',
        hidden = true,
        no_ignore = true,
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

            -- Ensure hidden/filtered items are visible in neo-tree
            local state = require('neo-tree.sources.manager').get_state('filesystem')
            if state and state.filtered_items and not state.filtered_items.visible then
              state.filtered_items.visible = true
            end

            require('neo-tree.command').execute({
              action = 'focus',
              source = 'filesystem',
              position = 'left',
              reveal_file = filepath,
              reveal_force_cwd = false,
            })
          end)
          return true
        end,
      })
    end

    -- ─────────────────────────────────────────────────────────
    -- Which-key group registration
    -- ─────────────────────────────────────────────────────────
    require('which-key').add({
      { mode = { 'n' }, { '<leader>f', group = '[f]ile explorer tree', hidden = false } },
    })

    -- ─────────────────────────────────────────────────────────
    -- Custom commands for neo-tree mappings
    -- ─────────────────────────────────────────────────────────
    local neo_tree_commands = {
      set_root_and_cd = function(state)
        local node = state.tree:get_node()
        if node then
          local path = node.type == 'directory' and node.path or vim.fn.fnamemodify(node.path, ':h')
          require('neo-tree.command').execute({
            action = 'focus',
            source = 'filesystem',
            dir = path,
          })
          vim.cmd('cd ' .. vim.fn.fnameescape(path))
        end
      end,

      go_to_parent = function(state)
        local node = state.tree:get_node()
        if node then
          local parent_id = node:get_parent_id()
          if parent_id then
            require('neo-tree.ui.renderer').focus_node(state, parent_id)
          end
        end
      end,

      go_to_next_expanded_folder = function(state)
        local node = state.tree:get_node()
        if not node then
          return
        end

        local start_line = vim.api.nvim_win_get_cursor(0)[1]
        local line_count = vim.api.nvim_buf_line_count(0)

        for i = start_line + 1, line_count do
          vim.api.nvim_win_set_cursor(0, { i, 0 })
          local next_node = state.tree:get_node(i)
          if next_node and next_node.type == 'directory' and next_node:is_expanded() then
            return
          end
        end

        vim.api.nvim_win_set_cursor(0, { start_line, 0 })
      end,

      telescope_find_dirs = function(_)
        telescope_find_dirs()
      end,

      telescope_find_files_reveal = function(_)
        telescope_find_files_reveal()
      end,
    
          telescope_find_files_hidden_reveal = function(_)
            telescope_find_files_hidden_reveal()
          end,
    }

    -- ─────────────────────────────────────────────────────────
    -- Sticky winbar: show current root path
    -- ─────────────────────────────────────────────────────────
    local function update_neo_tree_winbar()
      local state
      pcall(function()
        state = require('neo-tree.sources.manager').get_state('filesystem')
      end)
      if not state or not state.path then
        return
      end

      local root_name = vim.fn.fnamemodify(state.path, ':~')
      local winbar_str = '%#NeoTreeWinbar#  ' .. root_name .. '%*'

      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == 'neo-tree' then
          pcall(vim.api.nvim_set_option_value, 'winbar', winbar_str, { win = win })
        end
      end
    end

    -- ─────────────────────────────────────────────────────────
    -- Setup
    -- ─────────────────────────────────────────────────────────
    require('neo-tree').setup({
      close_if_last_window = false,
      hide_root_node = true,
      enable_git_status = true,
      enable_diagnostics = true,
      enable_modified_markers = true,
      enable_opened_markers = true,

      event_handlers = {
        {
          event = 'neo_tree_buffer_enter',
          handler = function()
            update_neo_tree_winbar()
            pcall(vim.keymap.del, 'n', '<leader>pwbfo')
            pcall(vim.keymap.del, 'n', '<leader>pwbfc')
          end,
        },
        {
          event = 'neo_tree_buffer_leave',
          handler = function()
            vim.keymap.set('n', '<leader>pwbfo', function()
              print(vim.fn.expand('%:p'))
            end, { desc = '[p]rint [w]orking [b]uffer [f]ilepath [o]utput' })

            vim.keymap.set('n', '<leader>pwbfc', function()
              vim.fn.setreg('+', vim.fn.expand('%:p'))
            end, { desc = '[p]rint [w]orking [b]uffer [f]ilepath to [c]lipboard' })
          end,
        },
        {
          event = 'after_render',
          handler = function()
            update_neo_tree_winbar()
          end,
        },
      },

      default_component_configs = {
        container = {
          enable_character_fade = true,
        },
        indent = {
          indent_size = 2,
          padding = 1,
          with_markers = true,
          indent_marker = '│',
          last_indent_marker = '└',
          with_expanders = false,
          highlight = 'NeoTreeIndentMarker',
        },
        icon = {
          folder_closed = '',
          folder_open = '',
          folder_empty = '󰉖',
          folder_empty_open = '󰷏',
        },
        modified = {
          symbol = '', -- Using custom icon
          highlight = 'NeoTreeModified',
        },
        name = {
          trailing_slash = false,
          highlight_opened_files = true,
          use_git_status_colors = true,
        },
        git_status = {
          symbols = {
            -- Change type
            added = '',
            modified = '',
            -- Status type
            unstaged = '󰜥',
            staged = '',
            untracked = '?',
            renamed = '󰑕',
            deleted = '',
            conflict = '',
            ignored = '',
          },
          align = 'right',
        },
      },
      renderers = {
        directory = {
          { 'indent' },
          { 'icon' },
          { 'current_filter' },
          {
            'container',
            content = {
              { 'visible_buffer_name', use_git_status_colors = true, zindex = 10 },
              { 'clipboard', zindex = 10 },
              { 'modified_custom', folder_highlight = 'NeoTreeModifiedFolderIcon', zindex = 20, align = 'right' },
              { 'diagnostics', errors_only = true, zindex = 20, align = 'right', hide_when_expanded = true },
              { 'git_status', zindex = 10, align = 'right', hide_when_expanded = true },
            },
          },
        },
        file = {
          { 'indent' },
          { 'icon' },
          {
            'container',
            content = {
              { 'visible_buffer_name', use_git_status_colors = true, zindex = 10 },
              { 'clipboard', zindex = 10 },
              { 'modified_custom', zindex = 20, align = 'right' },
              { 'diagnostics', zindex = 20, align = 'right' },
              { 'git_status', zindex = 10, align = 'right' },
            },
          },
        },
      },

      window = {
        position = 'left',
        width = 40,
        mapping_options = {
          noremap = true,
          nowait = true,
        },
        mappings = {
          ['<space>'] = 'none',
          ['<cr>'] = 'open',
          ['<2-LeftMouse>'] = 'open',
          ['<esc>'] = 'cancel',
          ['v'] = 'open_vsplit',
          ['s'] = 'open_split',
          ['.'] = {
            function(state)
              neo_tree_commands.set_root_and_cd(state)
            end,
            desc = 'Set root & cd',
          },
          ['-'] = 'navigate_up',
          ['u'] = 'navigate_up',
          ['P'] = {
            function(state)
              neo_tree_commands.go_to_parent(state)
            end,
            desc = 'Go to parent folder',
          },
          ['p'] = {
            function(state)
              neo_tree_commands.go_to_next_expanded_folder(state)
            end,
            desc = 'Go to next expanded folder below',
          },
          ['c'] = 'close_node',
          ['C'] = 'close_all_nodes',
          ['R'] = 'refresh',
          ['m'] = 'rename',
          ['a'] = 'add',
          ['A'] = 'add_directory',
          ['d'] = 'delete',
          ['y'] = 'copy_to_clipboard',
          ['x'] = 'cut_to_clipboard',
          ['?'] = 'show_help',
          ['q'] = 'close_window',
          ['<leader>sD'] = {
            function()
              telescope_find_dirs()
            end,
            desc = '[s]earch [D]irectories (reveal in tree)',
          },
          ['<leader>sf'] = {
            function()
              telescope_find_files_reveal()
            end,
            desc = '[s]earch [f]iles (reveal in tree)',
          },
          ['<leader>sF'] = {
            function()
              telescope_find_files_hidden_reveal()
            end,
            desc = '[s]earch [F]iles including hidden (reveal in tree)',
          },
        },
      },

      filesystem = {
        -- ─────────────────────────────────────────────────────
        -- Custom components registered per-source
        -- ─────────────────────────────────────────────────────
        components = {
          -- Override name: bold white for loaded buffers, bold orange for visible
          visible_buffer_name = function(config, node, state)
            local cc = require('neo-tree.sources.common.components')
            local result = cc.name(config, node, state)

            if node.type ~= 'directory' and node.path then
              local visible = vim.g.neo_tree_visible_file
              if visible and vim.fs.normalize(node.path) == visible then
                result.highlight = 'NeoTreeVisibleFile'
              elseif vim.fn.bufloaded(node.path) > 0 then
                result.highlight = 'NeoTreeFileNameOpened'
              end
            end

            return result
          end,

          -- [+] for modified files, … for folders with modified children
          -- Uses state.opened_buffers which has { modified = bool, loaded = bool } per path
          modified_custom = function(config, node, state)
            local opened_buffers = state.opened_buffers or {}
            local neo_tree_utils = require('neo-tree.utils')

            if node.type == 'file' then
              local buf_info = neo_tree_utils.index_by_path(opened_buffers, node.path)
              if buf_info and buf_info.modified then
                return {
                  text = '[+]',
                  highlight = 'NeoTreeModified',
                }
              end
            elseif node.type == 'directory' then
              for buf_path, buf_info in pairs(opened_buffers) do
                if buf_info.modified and vim.startswith(buf_path, node.path .. '/') then
                  return {
                    text = ' … ',
                    highlight = config.folder_highlight or 'NeoTreeModifiedFolderIcon',
                  }
                end
              end
            end

            return {}
          end,

          -- ─────────────────────────────────────────────────────
          -- Custom indent component matching nvim-tree style:
          --   ├ for non-last children (item connector)
          --   └ for last child (corner)
          --   │ for parent continuation lines (edge)
          -- ─────────────────────────────────────────────────────
          indent = function(config, node, state)
            local highlights = require('neo-tree.ui.highlights')
            local file_nesting = require('neo-tree.sources.common.file-nesting')

            if not state.skip_marker_at_level then
              state.skip_marker_at_level = {}
            end

            local indent_size = config.indent_size or 2
            local padding = config.padding or 0
            local level = node.level
            local with_markers = config.with_markers
            local with_expanders = config.with_expanders == nil and file_nesting.is_enabled() or config.with_expanders
            local marker_highlight = config.highlight or highlights.INDENT_MARKER
            local expander_highlight = config.expander_highlight or config.highlight or highlights.EXPANDER
            local skip_marker = state.skip_marker_at_level

            local edge_marker = config.indent_marker or '│'
            local corner_marker = config.last_indent_marker or '└'
            local item_marker = config.item_marker or '├'

            local function get_expander()
              if with_expanders and require('neo-tree.utils').is_expandable(node) then
                return node:is_expanded() and (config.expander_expanded or '') or (config.expander_collapsed or '')
              end
            end

            -- Only skip for root (level 0)
            if indent_size == 0 or level < 1 or not with_markers then
              local len = indent_size * level + padding
              local expander = get_expander()
              if level == 0 or not expander then
                return {
                  text = string.rep(' ', len),
                }
              end
              return {
                text = string.rep(' ', len - vim.fn.strdisplaywidth(expander) - 1) .. expander .. ' ',
                highlight = expander_highlight,
              }
            end

            skip_marker[level] = node.is_last_child
            local indent = {}

            if padding > 0 then
              table.insert(indent, { text = string.rep(' ', padding) })
            end

            for i = 1, level do
              local char = ''
              local spaces_count = indent_size
              local highlight = nil

              if i == level then
                -- This is the node's own level — draw the connector
                spaces_count = spaces_count - 1
                highlight = marker_highlight

                local expander = get_expander()
                if expander then
                  char = expander
                  highlight = expander_highlight
                elseif node.is_last_child then
                  char = corner_marker
                  spaces_count = spaces_count - (vim.api.nvim_strwidth(corner_marker) - 1)
                else
                  char = item_marker
                  spaces_count = spaces_count - (vim.api.nvim_strwidth(item_marker) - 1)
                end
              else
                -- Parent continuation levels — draw │ if parent is not last child
                if not skip_marker[i] then
                  char = edge_marker
                  spaces_count = spaces_count - 1
                  highlight = marker_highlight
                end
              end

              table.insert(indent, {
                text = char .. string.rep(' ', spaces_count),
                highlight = highlight,
                no_next_padding = true,
              })
            end

            return indent
          end,
        },

        bind_to_cwd = true,
        hijack_netrw_behavior = 'open_default',
        use_libuv_file_watcher = true,
        follow_current_file = {
          enabled = false,
        },
        filtered_items = {
          visible = false,
          hide_dotfiles = true,
          hide_gitignored = false,
        },
        window = {
          mappings = {
            ['f'] = 'filter_on_submit',
            ['F'] = 'clear_filter',
            ['H'] = 'toggle_hidden',
            ['/'] = 'none',
          },
        },
      },
    })

    -- ─────────────────────────────────────────────────────────
    -- Global keymaps (outside the tree buffer)
    -- ─────────────────────────────────────────────────────────
    vim.keymap.set('n', '<leader>fe', '<cmd>Neotree toggle<CR>', { desc = 'Toggle file explorer' })
    vim.keymap.set('n', '<leader>ef', '<cmd>Neotree focus<CR>', { desc = 'Focus file explorer' })
    vim.keymap.set('n', '<leader>er', '<cmd>Neotree refresh<CR>', { desc = 'Refresh file explorer' })

    vim.keymap.set('n', '<leader>fF', function()
      require('neo-tree.command').execute({
        action = 'focus',
        source = 'filesystem',
        position = 'left',
        reveal = true,
        reveal_force_cwd = false,
      })
    end, { desc = 'Find File in Neo-tree' })
  end,
}
