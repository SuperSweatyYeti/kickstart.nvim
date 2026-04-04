--
-- OSC52 yank-only + Yanky setup + preserve-yank delete behavior
--
-- Requirements / behavior:
--   - OSC52 for SSH clipboard: copy ONLY on yank (never on delete/change)
--   - p/P should always paste the last explicit yank (unnamed register preserved)
--   - delete/change should NOT clobber unnamed or clipboard
--   - but delete/change should still be saved to register "1
--
-- NOTE:
--   This file assumes the plugins are installed via lazy specs (lua/custom/plugins/*.lua):
--     - ojroques/nvim-osc52
--     - gbprod/yanky.nvim
--   Do NOT set vim.g.clipboard = { ... osc52 ... } anywhere else.

------------------------------------------------------------
-- 1) OSC52: copy ONLY on yank, ONLY in SSH sessions
------------------------------------------------------------
do
  local in_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CLIENT ~= nil or vim.env.SSH_CONNECTION ~= nil

  if in_ssh then
    vim.opt.clipboard = ''

    local ok_osc, osc52 = pcall(require, 'osc52')
    if ok_osc then
      osc52.setup {
        max_length = 50000,
        trim = false,
        silent = true,
      }

      vim.api.nvim_create_autocmd('TextYankPost', {
        group = vim.api.nvim_create_augroup('custom_osc52_yank_only', { clear = true }),
        callback = function()
          if vim.v.event.operator == 'y' then
            osc52.copy_register '"'
          end
        end,
      })
    end
  end
end

------------------------------------------------------------
-- 2) Yanky: setup + history keymaps
------------------------------------------------------------
do
  local ok_yanky, yanky = pcall(require, 'yanky')
  if ok_yanky then
    yanky.setup {}
  end

  local picker_opts = {
    prompt_title = 'Ring History',
    sorting_strategy = 'ascending',
    layout_strategy = 'vertical',
    layout_config = {
      prompt_position = 'top',
      preview_cutoff = 1,
      preview_height = 0.4,
      mirror = true,
    },
  }

  vim.keymap.set('n', '<Leader>yh', function()
    require('telescope').extensions.yank_history.yank_history(picker_opts)
  end, { silent = true, desc = 'Yanky history' })

  vim.keymap.set({ 'x' }, '<Leader>p', function()
    require('telescope').extensions.yank_history.yank_history(picker_opts)
  end, { silent = true, desc = 'Yanky history' })

  vim.keymap.set('n', '<c-n>', '<Plug>(YankyCycleForward)', {})
  vim.keymap.set('n', '<c-p>', '<Plug>(YankyCycleBackward)', {})
end
------------------------------------------------------------
-- 3) Preserve last yank for p/P, but keep deletes accessible in register "1
------------------------------------------------------------
do
  local in_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CLIENT ~= nil or vim.env.SSH_CONNECTION ~= nil

  ---@param keys string  the raw key(s) to feed, e.g. "d", "c", "x", "s"
  local function op_to_reg1(keys)
    local prev_contents = vim.fn.getreg '"'
    local prev_type = vim.fn.getregtype '"'

    local prev_plus, prev_plus_type, prev_star, prev_star_type
    if not in_ssh then
      prev_plus = vim.fn.getreg '+'
      prev_plus_type = vim.fn.getregtype '+'
      prev_star = vim.fn.getreg '*'
      prev_star_type = vim.fn.getregtype '*'
    end

    local group = vim.api.nvim_create_augroup('_yank_preserve_swap', { clear = true })

    vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertEnter' }, {
      group = group,
      once = true,
      callback = function()
        local deleted_contents = vim.fn.getreg '"'
        local deleted_type = vim.fn.getregtype '"'

        vim.fn.setreg('1', deleted_contents, deleted_type)
        vim.fn.setreg('"', prev_contents, prev_type)

        if not in_ssh then
          vim.fn.setreg('+', prev_plus, prev_plus_type)
          vim.fn.setreg('*', prev_star, prev_star_type)
        end

        vim.api.nvim_del_augroup_by_id(group)
      end,
    })

    vim.api.nvim_feedkeys(keys, 'n', false)
  end

  -- (rest of keymaps unchanged)

  -- Normal mode: only map the operators and single-key commands.
  -- d/c are operators — Vim will wait for a motion natively,
  -- so dd, dw, d$, D, cc, cw, c$, C all work through these.
  vim.keymap.set('n', 'd', function()
    op_to_reg1 'd'
  end, { noremap = true, silent = true, desc = 'Delete -> reg 1 (preserve yank)' })
  vim.keymap.set('n', 'c', function()
    op_to_reg1 'c'
  end, { noremap = true, silent = true, desc = 'Change -> reg 1 (preserve yank)' })
  vim.keymap.set('n', 'x', function()
    op_to_reg1 'x'
  end, { noremap = true, silent = true, desc = 'x -> reg 1 (preserve yank)' })
  vim.keymap.set('n', 's', function()
    op_to_reg1 's'
  end, { noremap = true, silent = true, desc = 's -> reg 1 (preserve yank)' })

  -- Visual mode
  vim.keymap.set('x', 'd', function()
    op_to_reg1 'd'
  end, { noremap = true, silent = true, desc = 'V delete -> reg 1 (preserve yank)' })
  vim.keymap.set('x', 'c', function()
    op_to_reg1 'c'
  end, { noremap = true, silent = true, desc = 'V change -> reg 1 (preserve yank)' })

  -- Visual paste: don't overwrite last yank with replaced text
  vim.keymap.set('x', 'p', '"_dP', { noremap = true, silent = true, desc = 'Visual paste (preserve yank)' })
end


-- ====================================================
-- Select All Keymaps
-- ====================================================
-- Keymap to visually select everything in the current buffer
vim.keymap.set('n', '<leader>vaa', 'ggVG', { noremap = true, desc = '[v]isually select [a]ll text from current buffer' })
-- Keymap to delete everything in the current buffer AND DON'T clobber system clipboard add to yank history instead
vim.keymap.set('n', '<leader>vad', function()
  local in_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CLIENT ~= nil or vim.env.SSH_CONNECTION ~= nil

  local prev_contents = vim.fn.getreg '"'
  local prev_type = vim.fn.getregtype '"'

  local prev_plus, prev_plus_type, prev_star, prev_star_type
  if not in_ssh then
    prev_plus = vim.fn.getreg '+'
    prev_plus_type = vim.fn.getregtype '+'
    prev_star = vim.fn.getreg '*'
    prev_star_type = vim.fn.getregtype '*'
  end

  vim.cmd 'normal! ggVGd'

  local deleted_contents = vim.fn.getreg '"'
  local deleted_type = vim.fn.getregtype '"'

  vim.fn.setreg('1', deleted_contents, deleted_type)
  vim.fn.setreg('"', prev_contents, prev_type)

  if not in_ssh then
    vim.fn.setreg('+', prev_plus, prev_plus_type)
    vim.fn.setreg('*', prev_star, prev_star_type)
  end
end, { noremap = true, desc = '[v]isually select [a]ll text from current buffer and [d]elete' })

-- Keymap to yank everything in the current buffer V2
-- Add which-key-group
require('which-key').add {
  { mode = { 'n' }, { '<leader>v', group = '[v]isual selection', hidden = false } },
  { mode = { 'n' }, { '<leader>va', group = '[v]isually select [a]ll', hidden = false } },
}
vim.keymap.set('n', '<leader>vay', function()
  vim.cmd('%y')
end, { desc = '[v]isually select [a]ll text from current buffer and [y]ank' })

