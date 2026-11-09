return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',
  config = function()
    -- Similar to Noice
    require('mini.notify').setup()

    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [']quote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup({ n_lines = 500 })

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --  "Hellowsum"
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup()

    -- VScode like indent highlighting
    require('mini.indentscope').setup({
      draw = {
        animation = require('mini.indentscope').gen_animation.none(), -- Disable animation for indent scope
      },
      mappings = {
        object_scope = 'is',
      },
    })

    -- Inline hunk review (e.g. after Claude edits a file): toggle the overlay to
    -- see deleted/added text in the same buffer, then accept or deny per hunk.
    -- Reference is the git index, so "accept" stages the hunk and "deny" reverts it
    --  - <leader>ao - toggle [o]verlay
    --  - ]h / [h    - next / previous hunk
    --  - ghgh       - accept (stage) hunk under cursor; gh in visual for a range
    --  - gHgh       - deny (reset) hunk under cursor
    require('mini.diff').setup({
      -- Color line numbers instead of signs so it doesn't clash with gitsigns
      view = { style = 'number' },
    })
    vim.keymap.set('n', '<leader>ao', function()
      MiniDiff.toggle_overlay()
      local data = MiniDiff.get_buf_data()
      vim.notify('Diff overlay ' .. ((data and data.overlay) and 'enabled' or 'disabled'))
    end, { desc = 'Toggle diff overlay' })

    -- Simple and easy statusline.
    --  You could remove this setup call if you don't like it,
    --  and try some other statusline plugin

    -- -- STATUS LINE
    -- local statusline = require 'mini.statusline'
    -- -- set use_icons to true if you have a Nerd Font
    -- statusline.setup { use_icons = vim.g.have_nerd_font }
    --
    -- -- You can configure sections in the statusline by overriding their
    -- -- default behavior. For example, here we set the section for
    -- -- cursor location to LINE:COLUMN
    -- -@diagnostic disable-next-line: duplicate-set-field
    -- statusline.section_location = function()
    --   return '%2l:%-2v'
    -- end

    -- ... and there is more!
    --  Check out: https://github.com/echasnovski/mini.nvim
  end,
}
