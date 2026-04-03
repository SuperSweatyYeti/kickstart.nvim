return {
  -- NOTE: Plugins can specify dependencies.
  --
  -- The dependencies are proper plugin specifications as well - anything
  -- you do for a plugin at the top level, you can do for a dependency.
  --
  -- Use the `dependencies` key to specify the dependencies of a particular plugin

  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    enabled = true,
    event = 'VimEnter',
    -- branch = '',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for install instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      -- Useful for getting pretty icons, but requires special font.
      --  If you already have a Nerd Font, or terminal set up with fallback fonts
      --  you can enable this
      -- { 'nvim-tree/nvim-web-devicons' }
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of help_tags options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      local actions = require 'telescope.actions'
      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        defaults = {
          mappings = {
            i = { ['JJ'] = actions.close },
          },
        },
        -- pickers = {}
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      -- Enable telescope extensions, if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[s]earch [h]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[s]earch [k]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[s]earch [f]iles' })
      vim.keymap.set('n', '<leader>sF', '<cmd>Telescope find_files hidden=true <enter>', { desc = '[s]earch [f]iles include hidden' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[s]earch [s]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[s]earch current [w]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[s]earch by [g]rep' })
      vim.keymap.set('n', '<leader>sG', function()
        builtin.live_grep {
          additional_args = function()
            return { '--no-ignore', '--hidden' }
          end,
        }
      end, { desc = '[s]earch by [g]rep include hidden' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[s]earch [d]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[s]earch [r]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[s]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      -- Search For Directories only
      -- Custom stuff to add folder icons and previewer
      vim.keymap.set('n', '<leader>sD', function()
        local entry_display = require 'telescope.pickers.entry_display'
        local pickers = require 'telescope.pickers'
        local finders = require 'telescope.finders'
        local previewers = require 'telescope.previewers'
        local from_entry = require 'telescope.from_entry'
        local conf = require('telescope.config').values
        local utils = require 'telescope.utils'
        local Path = require 'plenary.path'

        local cwd = vim.uv.cwd()

        local displayer = entry_display.create {
          separator = ' ',
          items = {
            { width = 2 },
            { remaining = true },
          },
        }

        local lookup_keys = {
          ordinal = 1,
          value = 1,
          filename = 1,
          cwd = 2,
        }

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

                local lines = {}
                local hl_lines = {}
                for _, item in ipairs(results) do
                  local name = vim.fn.fnamemodify(item, ':t')
                  local stat = vim.uv.fs_stat(item)
                  if stat and stat.type == 'directory' then
                    table.insert(lines, ' ' .. name)
                    table.insert(hl_lines, 'Directory')
                  else
                    table.insert(lines, '  ' .. name)
                    table.insert(hl_lines, 'TelescopePreviewNormal')
                  end
                end

                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

                local ns = vim.api.nvim_create_namespace 'dir_preview'
                for i, hl_group in ipairs(hl_lines) do
                  -- highlight the icon
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
          })
          :find()
      end, { desc = '[s]earch [D]irectories' })
      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to telescope to change theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      -- Also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[s]earch [/] in Open Files' })

      -- Shortcut for searching your neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[s]earch [n]eovim files' })
    end,
  },
}
