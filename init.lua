--[[
-- Test comment
=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========         `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================

What is Kickstart?

  Kickstart.nvim is *not* a distribution.

  Kickstart.nvim is a starting point for your own configuration.
    The goal is that you can read every line of code, top-to-bottom, understand
    what your configuration is doing, and modify it to suit your needs.

    Once you've done that, you can start exploring, configuring and tinkering to
    make Neovim your own! That might mean leaving kickstart just the way it is for a while
    or immediately breaking it into modular pieces. It's up to you!

    If you don't know anything about Lua, I recommend taking some time to read through
    a guide. One possible example which will only take 10-15 minutes:
      - https://learnxinyminutes.com/docs/lua/

    After understanding a bit more about Lua, you can use `:help lua-guide` as a
    reference for how Neovim integrates Lua.
    - :help lua-guide
    - (or HTML version): https://neovim.io/doc/user/lua-guide.html

Kickstart Guide:

  TODO: The very first thing you should do is to run the command `:Tutor` in Neovim.

    If you don't know what this means, type the following:
      - <escape key>
      - :
      - Tutor
      - <enter key>

    (If you already know how the Neovim basics, you can skip this step)

  Once you've completed that, you can continue working through **AND READING** the rest
  of the kickstart init.lua

  Next, run AND READ `:help`.
    This will open up a help window with some basic information
    about reading, navigating and searching the builtin help documentation.

    This should be the first place you go to look when you're stuck or confused
    with something. It's one of my favorite neovim features.

    MOST IMPORTANTLY, we provide a keymap "<space>sh" to [s]earch the [h]elp documentation,
    which is very useful when you're not sure exactly what you're looking for.

  I have left several `:help X` comments throughout the init.lua
    These are hints about where to find more information about the relevant settings,
    plugins or neovim features used in kickstart.

   NOTE: Look for lines like this

    Throughout the file. These are for you, the reader, to help understand what is happening.
    Feel free to delete them once you know what you're doing, but they should serve as a guide
    for when you are first encountering a few different constructs in your nvim config.

If you experience any errors while trying to install kickstart, run `:checkhealth` for more info

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now! :)
--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
-- Set conceal level which lets certain plugins render/transform text
-- vim.opt.conceallevel = 2

-- NOTE: these options might be viable in versions
-- of neovim 0.11+ possbily soon ??
--
-- vim.g.winborder = 'rounded'
-- vim.opt.winborder = 'rounded'

-- Use borders for completion and documentation windows from plugins
-- Might not need if above options start working
vim.o.winborder = 'rounded'

-- Set to true if you have a Nerd Font installed
vim.g.have_nerd_font = true

-- NOTE: Detect our OS here
-- We may need to enable or disable stuff based on our OS type
vim.g.OSName = vim.loop.os_uname().sysname

---
-- Checks if the operating system is Windows.
-- @return boolean true if the OS name contains "windows", otherwise false.
---
function is_os_windows()
  local os_name = vim.g.OSName or ''
  -- Check if the lowercase version of the OS name contains "windows".
  if string.find(string.lower(os_name), 'windows') then
    -- If the substring is found, explicitly return true.
    return true
  else
    -- If the substring is not found, explicitly return false.
    return false
  end
end

---
-- Checks if the operating system is Linux.
-- @return boolean true if the OS name contains "linux", otherwise false.
---
function is_os_linux()
  local os_name = vim.g.OSName or ''
  -- Check if the lowercase version of the OS name contains "linux".
  if string.find(string.lower(os_name), 'linux') then
    -- If the substring is found, explicitly return true.
    return true
  else
    -- If the substring is not found, explicitly return false.
    return false
  end
end

---
-- Checks if the operating system is Mac os.
-- @return boolean true if the OS name contains "darwin", otherwise false.
---
function is_os_darwin()
  local os_name = vim.g.OSName or ''
  -- Check if the lowercase version of the OS name contains "darwin".
  if string.find(string.lower(os_name), 'darwin') then
    -- If the substring is found, explicitly return true.
    return true
  else
    -- If the substring is not found, explicitly return false.
    return false
  end
end

-- Disable focus tracking ( In linux neovim tries to re-grab window focus )
if is_os_linux then
  vim.opt.eventignore:append 'FocusLost'
end

-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, for help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Don't show the mode, since it's already in status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.opt.clipboard = 'unnamedplus'

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- NOTE: debugging lua code here
-- Recursive function to print a table's contents

function lua_print(item, indent)
  indent = indent or 0
  local spaces = string.rep('  ', indent)

  if type(item) == 'table' then
    print(spaces .. '{')
    for key, value in pairs(item) do
      local key_str = (type(key) == 'string') and key or ('[' .. tostring(key) .. ']')
      if type(value) == 'table' then
        print(spaces .. '  ' .. key_str .. ': {')
        print_item(value, indent + 2)
        print(spaces .. '  }')
      else
        print(spaces .. '  ' .. key_str .. ': ' .. tostring(value))
      end
    end
    print(spaces .. '}')
  else
    print(spaces .. tostring(item))
  end
end

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Easier to close buffer
vim.keymap.set('n', '<leader>C', '<cmd>q<CR>', { desc = '[C]lose Buffer' })
-- Easier to refresh current buffer
vim.keymap.set('n', '<leader>br', '<cmd>e!<CR>', { desc = '[r]efresh Buffer check for file updates' })
-- Easier to refresh current ALL buffers
vim.keymap.set('n', '<leader>bR', '<cmd>bufdo e<CR>', { desc = '[r]efresh ALL Buffers check for file updates' })
-- Easier to delete buffer
-- Actually sends buffer wipeout command
vim.keymap.set('n', '<leader>bd', '<cmd>bw<CR>', { desc = '[d]elete buffer' })
-- Step back and forth through buffer history
vim.keymap.set('n', '<leader>bn', '<cmd>bNext<CR>', { desc = '[n]ext buffer' })
vim.keymap.set('n', '<leader>bp', '<cmd>bprevious<CR>', { desc = '[p]revious buffer' })
-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [d]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [d]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [e]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- NOTE:
-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
--
--  Backup config KickStart
-- vim.api.nvim_create_autocmd('TextYankPost', {
--   desc = 'Highlight when yanking (copying) text',
--   group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
--   callback = function()
--     vim.highlight.on_yank()
--   end,
-- })
-- Backup config KickStart end

-- -- Backup AI
-- -- Function to perform yank + highlight + restore cursor
-- local function yank_and_restore_cursor(type)
--   local curpos = vim.api.nvim_win_get_cursor(0)
--
--   -- Yank based on type
--   if type == 'v' or type == 'V' or type == '\22' then  -- visual, line, block
--     vim.cmd('normal! "' .. vim.v.register .. 'y' )
--   else
--     vim.cmd('normal! "' .. vim.v.register .. 'y' .. type)
--   end
--
--   -- Highlight
--   vim.highlight.on_yank { higroup = 'IncSearch', timeout = 200 }
--
--   -- Restore cursor
--   vim.defer_fn(function()
--     pcall(vim.api.nvim_win_set_cursor, 0, curpos)
--   end, 10)
-- end
--
-- -- Visual mode mapping
-- vim.keymap.set({ 'v','x' }, 'y', function()
--   yank_and_restore_cursor(vim.fn.visualmode())
-- end, { noremap = true, silent = true })
-- -- Bacup AI end

-- -- NOTE: Better yank behavior
-- Normally When yanking a chunk of text the cursor goes to top of paragraph.
-- I am changing that behavior here. The cursor stays where it was initially when yanking
-- a visual line selection for example.

-- Define the operatorfunc to yank + highlight + restore cursor
_G.yank_and_restore_cursor = function(type)
  if type == 'char' then
    vim.cmd 'normal! `[v`]y'
  elseif type == 'line' then
    vim.cmd 'normal! `[V`]y'
  elseif type == 'block' then
    vim.cmd 'normal! `[\22`]y' -- \22 is <C-v> for block
  end

  vim.highlight.on_yank { higroup = 'IncSearch', timeout = 200 }

  vim.defer_fn(function()
    if _G._saved_cursor then
      pcall(vim.api.nvim_win_set_cursor, 0, _G._saved_cursor)
    end
  end, 10)
end

-- Normal mode 'y' remap to use operatorfunc with saved cursor
vim.keymap.set('n', 'y', function()
  _G._saved_cursor = vim.api.nvim_win_get_cursor(0)
  vim.o.operatorfunc = 'v:lua.yank_and_restore_cursor'
  return 'g@'
end, { expr = true, noremap = true })

-- Visual mode 'y' remap to yank + restore cursor
vim.keymap.set('x', 'y', function()
  _G._saved_cursor = vim.api.nvim_win_get_cursor(0)
  vim.cmd 'normal! y'
  vim.highlight.on_yank { higroup = 'IncSearch', timeout = 200 }
  vim.defer_fn(function()
    pcall(vim.api.nvim_win_set_cursor, 0, _G._saved_cursor)
  end, 10)
end, { noremap = true, silent = true })

-- Make 'yy' reuse the same yank logic via motion
vim.keymap.set('n', 'yy', 'y_', { noremap = true, silent = true })

-- Async internet check: tries each IP in order, stops on first success
-- Usage: pass the result of this to any plugin's `enabled` field
-- e.g. enabled = _G.internet_check.is_available
_G.internet_check = (function()
  local state = { available = true } -- optimistic default

  local function ping_unix(ip, on_done)
    local stdout = vim.uv.new_pipe()
    local stderr = vim.uv.new_pipe()
    local handle
    handle = vim.uv.spawn('ping', {
      args = { '-c', '2', '-W', '2', ip },
      stdio = { nil, stdout, stderr },
    }, function(code)
      stdout:close()
      stderr:close()
      handle:close()
      on_done(code == 0)
    end)
  end

  local function ping_windows(ip, on_done)
    local stdout = vim.uv.new_pipe()
    local stderr = vim.uv.new_pipe()
    local handle
    handle = vim.uv.spawn('ping', {
      args = { '-n', '2', '-w', '2000', ip },
      stdio = { nil, stdout, stderr },
    }, function(code)
      stdout:close()
      stderr:close()
      handle:close()
      on_done(code == 0)
    end)
  end

  local ping = is_os_windows() and ping_windows or ping_unix

  -- Ordered list of IPs to try — edit to add/remove/reorder
  local dns_hosts = {
    '1.1.1.1', -- Cloudflare
    '8.8.8.8', -- Google
    '9.9.9.9', -- Quad9
  }

  -- Recursively try each IP in order, stop on first success
  local function try_hosts(hosts, index, on_done)
    if index > #hosts then
      on_done(false)
      return
    end
    ping(hosts[index], function(ok)
      if ok then
        on_done(true)
      else
        try_hosts(hosts, index + 1, on_done)
      end
    end)
  end

  -- Fire immediately at startup in the background
  try_hosts(dns_hosts, 1, function(ok)
    state.available = ok
    if not ok then
      vim.schedule(function()
        vim.notify('No internet — network-dependent plugins disabled', vim.log.levels.WARN)
      end)
    end
  end)

  return {
    -- Pass this function reference directly to `enabled =` in any plugin spec
    is_available = function()
      return state.available
    end,
  }
end)()

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins, you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require('lazy').setup({
  -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to force a plugin to be loaded.
  --
  --  This is equivalent to:
  --    require('Comment').setup({})

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },

  -- Here is a more advanced example where we pass configuration
  -- options to `gitsigns.nvim`. This is equivalent to the following lua:
  --    require('gitsigns').setup({ ... })
  --
  -- See `:help gitsigns` to understand what the configuration keys do
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  -- NOTE: Plugins can also be configured to run lua code when they are loaded.
  --
  -- This is often very useful to both group configuration, as well as handle
  -- lazy loading plugins that don't need to be loaded immediately at startup.
  --
  -- For example, in the following configuration, we use:
  --  event = 'VimEnter'
  --
  -- which loads which-key before all the UI elements are loaded. Events can be
  -- normal autocommands events (`:help autocmd-events`).
  --
  -- Then, because we use the `config` key, the configuration only runs
  -- after the plugin has been loaded:
  --  config = function() ... end

  -- NOTE: Plugins can specify dependencies.
  --
  -- The dependencies are proper plugin specifications as well - anything
  -- you do for a plugin at the top level, you can do for a dependency.
  --
  -- Use the `dependencies` key to specify the dependencies of a particular plugin

  -- Highlight todo, notes, etc in comments
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },

  -- The following two comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- put them in the right spots if you want.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for kickstart
  --
  --  Here are some example plugins that I've included in the kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  -- require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --    For additional information, see `:help lazy.nvim-lazy.nvim-structuring-your-plugins`
  { import = 'custom.plugins' },
  { import = 'custom.themes' },
}, {
  rocks = {
    hererocks = true,
  },
  ui = {
    -- If you have a Nerd Font, set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- NOTE: You can import other lua settings folders here.
-- We are using the plenary plugin to make loading all lua config files within
-- a folder more dynamic. See this file for an example: ./lua/custom/settings/init.lua
-- Each folder you import needs to have it's own init.lua file following the example.
require 'custom.settings'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
