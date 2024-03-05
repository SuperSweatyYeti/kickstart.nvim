-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  -- Quickscope
  {
    'unblevable/quick-scope',
    -- Quickscope only highlight when f search
    vim.cmd [[
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
autocmd ColorScheme * highlight QuickScopePrimary guifg='#afff5f' gui=underline ctermfg=155 cterm=underline
autocmd ColorScheme * highlight QuickScopeSecondary guifg='#5fffff' gui=underline ctermfg=81 cterm=underline
]],
  },

  -- ToggleTerm
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    opts = {
      --[[ things you want to change go here]]
      vim.keymap.set('t', 'ii', [[<C-\><C-n>]]),
      vim.keymap.set('n', '<leader>t', [[:ToggleTerm<enter>]]),
      vim.keymap.set('t', '<C-k>', [[<C-\><C-n><C-w>k]], {}),
      vim.keymap.set('t', '<C-h>', [[<C-\><C-n><C-w>h]], {}),
    },
  },

  -- Neo-Tree file pane
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
    'gbprod/yanky.nvim',
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },

  {

    ------------------ Custom Keymaps ---------------------------------

    -- Easier to change back to normal mode 'Double tap i'
    vim.keymap.set({ 'v', 'i' }, 'ii', '<Esc><Esc>', {}),
    -- Quickly get to end and beggining of line
    vim.keymap.set('n', '<S-h>', '<Home>', {}),
    vim.keymap.set('n', '<S-l>', '<End>', {}),
    -- vim.keymap.set('v', 'ii', "<Esc>", {})
    -- Easier to navigate between panes
    vim.keymap.set('n', '<C-h>', '<C-w>h', {}),
    vim.keymap.set('n', '<C-j>', '<C-w>j', {}),
    vim.keymap.set('n', '<C-k>', '<C-w>k', {}),
    vim.keymap.set('n', '<C-l>', '<C-w>l', {}),
    -- Resize panes with hjkl
    vim.keymap.set('n', '<A-h>', '<C-w><', {}),
    vim.keymap.set('n', '<A-j>', '<C-w>+', {}),
    vim.keymap.set('n', '<A-k>', '<C-w>-', {}),
    vim.keymap.set('n', '<A-l>', '<C-w>>', {}),
    -- Change tabs with hjkl
    vim.keymap.set('n', '<leader>Th', ':tabprevious\n', {}),
    vim.keymap.set('n', '<leader>Tl', ':tabnext\n', {}),
    vim.keymap.set('n', '<A-L>', ':tabnext\n', {}),
    vim.keymap.set('n', '<A-H>', ':tabprevious\n', {}),

    ------------------ END Custom Keymaps -----------------------------
  },
}
