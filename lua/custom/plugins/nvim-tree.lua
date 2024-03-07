return {
  -- {
  --   'nvim-tree/nvim-tree.lua',
  --   config = function()
  --     vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true })
  --   end,
  --   require('nvim-tree').setup(),
  -- },

  -- -- Side Folder Navigation Nvim Tree
  -- {
  --   'nvim-tree/nvim-tree.lua',
  --   version = '*',
  --   api = require 'nvim-tree.api',
  --   opts = {
  --     -- See top of file need to disable netrw
  --     vim.keymap.set('n', '<leader>f', [[:NvimTreeToggle<enter>]]),
  --   },
  -- },
  -- -- Side Folder Navigation Nvim Tree ICONS
  -- { 'nvim-tree/nvim-web-devicons', version = '*', opts = {} },

  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
      -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    opts = {
      -- See top of file need to disable netrw
      vim.keymap.set('n', '<leader>f', [[:Neotree toggle<enter>]]),
    },
    config = function()
      require('neo-tree').setup {

        -- A list of functions, each representing a global custom command
        -- that will be available in all sources (if not overridden in `opts[source_name].commands`)
        -- see `:h neo-tree-custom-commands-global`
        commands = {},
        window = {
          position = 'left',
          width = 40,
          mapping_options = {
            noremap = false,
            nowait = true,
          },
          mappings = {
            ['u'] = 'navigate_up',
            ['.'] = 'set_root',
            ['E'] = {
              'toggle_node',
              nowait = false, -- disable `nowait` if you have existing combos starting with this char that you want to use
            },
            -- Read `# Preview Mode` for more information
            ['l'] = 'focus_preview',
            ['S'] = 'open_split',
            ['s'] = 'open_vsplit',
            -- ["S"] = "split_with_window_picker",
            -- ["s"] = "vsplit_with_window_picker",
            ['<leader>n'] = 'open_tabnew',
            -- ["<cr>"] = "open_drop",
            -- ['t'] = 'open_tab_drop',
            ['w'] = 'open_with_window_picker',
            --["P"] = "toggle_preview", -- enter preview mode, which shows the current node without focusing
            ['C'] = 'close_node',
            -- ['C'] = 'close_all_subnodes',
            ['z'] = 'close_all_nodes',
            --["Z"] = "expand_all_nodes",
            ['a'] = {
              'add',
              -- this command supports BASH style brace expansion ("x{a,b,c}" -> xa,xb,xc). see `:h neo-tree-file-actions` for details
              -- some commands may take optional config options, see `:h neo-tree-mappings` for details
              config = {
                show_path = 'none', -- "none", "relative", "absolute"
              },
            },
            ['A'] = 'add_directory', -- also accepts the optional config.show_path option like "add". this also supports BASH style brace expansion.
            ['d'] = 'delete',
            ['r'] = 'rename',
            ['y'] = 'copy_to_clipboard',
            ['x'] = 'cut_to_clipboard',
            ['p'] = 'paste_from_clipboard',
            ['c'] = 'copy', -- takes text input for destination, also accepts the optional config.show_path option like "add":
            -- ["c"] = {
            --  "copy",
            --  config = {
            --    show_path = "none" -- "none", "relative", "absolute"
            --  }
            --}
            ['m'] = 'move', -- takes text input for destination, also accepts the optional config.show_path option like "add".
            ['q'] = 'close_window',
            ['R'] = 'refresh',
            ['?'] = 'show_help',
            ['<'] = 'prev_source',
            ['>'] = 'next_source',
            ['i'] = 'show_file_details',
          },
        },
      }
    end,
  },
}
