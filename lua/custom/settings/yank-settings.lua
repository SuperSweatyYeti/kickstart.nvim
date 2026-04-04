-- lua/custom/settings/yank-settings.lua
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
-- 1) OSC52: copy ONLY on yank
------------------------------------------------------------
do
  local ok_osc, osc52 = pcall(require, "osc52")
  if ok_osc then
    osc52.setup({
      max_length = 50000,
      trim = false,
      silent = false,
    })

    vim.api.nvim_create_autocmd("TextYankPost", {
      group = vim.api.nvim_create_augroup("custom_osc52_yank_only", { clear = true }),
      callback = function()
        if vim.v.event.operator == "y" then
          osc52.copy_register('"')
        end
      end,
    })
  end
end

------------------------------------------------------------
-- 2) Yanky: setup + history keymaps
------------------------------------------------------------
do
  local ok_yanky, yanky = pcall(require, "yanky")
  if ok_yanky then
    yanky.setup({
      registers = { '"', "0", "1", "+", "*" },
    })
  end

  vim.keymap.set("n", "<Leader>yh", "<cmd>YankyRingHistory<CR>", { silent = true, desc = "Yanky history" })
  vim.keymap.set({ "x" }, "<Leader>p", "<cmd>YankyRingHistory<CR>", { silent = true, desc = "Yanky history" })
  vim.keymap.set("n", "<c-n>", "<Plug>(YankyCycleForward)", {})
  vim.keymap.set("n", "<c-p>", "<Plug>(YankyCycleBackward)", {})
end

------------------------------------------------------------
-- 3) Preserve last yank for p/P, but keep deletes accessible in register "1
--
--    Approach: save unnamed register before the operation, let Vim do the
--    native d/c/x/s (which writes to unnamed), then move that into reg 1
--    and restore the original unnamed register. This way Vim handles all
--    cursor positioning, modes, linewise/charwise/blockwise, counts, and
--    motions natively — zero edge cases.
------------------------------------------------------------
do
  --- Perform a destructive operator natively, then move the result from
  --- the unnamed register into register 1 and restore the previous unnamed.
  ---@param keys string  the raw key(s) to feed, e.g. "d", "c", "x", "s"
  local function op_to_reg1(keys)
    -- Snapshot what's currently in the unnamed register
    local prev_contents = vim.fn.getreg('"')
    local prev_type = vim.fn.getregtype('"')

    -- Build the feedkeys string: use the unnamed register (default behavior)
    -- so Vim does everything natively, then our autocmd on TextYankPost
    -- or an operatorfunc-end callback fixes the registers.
    --
    -- We can't do this synchronously because the operator hasn't happened yet
    -- when this function runs. Instead we use feedkeys + a one-shot CursorMoved
    -- (or TextChanged) autocmd to do the register swap after Vim finishes.

    local group = vim.api.nvim_create_augroup("_yank_preserve_swap", { clear = true })

    -- Use TextChanged — fires once after the buffer is modified by the operator
    vim.api.nvim_create_autocmd({ "TextChanged", "InsertEnter" }, {
      group = group,
      once = true,
      callback = function()
        -- The operator just ran. The deleted/changed text is now in unnamed.
        local deleted_contents = vim.fn.getreg('"')
        local deleted_type = vim.fn.getregtype('"')

        -- Move it to register 1
        vim.fn.setreg("1", deleted_contents, deleted_type)

        -- Restore the previous unnamed register (the last yank)
        vim.fn.setreg('"', prev_contents, prev_type)

        vim.api.nvim_del_augroup_by_id(group)
      end,
    })

    -- Feed the keys normally — Vim handles everything
    vim.api.nvim_feedkeys(keys, "n", false)
  end

  -- Normal mode
  vim.keymap.set("n", "d", function() op_to_reg1("d") end,
    { noremap = true, silent = true, desc = "Delete -> reg 1 (preserve yank)" })
  vim.keymap.set("n", "dd", function() op_to_reg1("dd") end,
    { noremap = true, silent = true, desc = "Delete line -> reg 1 (preserve yank)" })
  vim.keymap.set("n", "D", function() op_to_reg1("D") end,
    { noremap = true, silent = true, desc = "Delete to EOL -> reg 1 (preserve yank)" })
  vim.keymap.set("n", "c", function() op_to_reg1("c") end,
    { noremap = true, silent = true, desc = "Change -> reg 1 (preserve yank)" })
  vim.keymap.set("n", "cc", function() op_to_reg1("cc") end,
    { noremap = true, silent = true, desc = "Change line -> reg 1 (preserve yank)" })
  vim.keymap.set("n", "C", function() op_to_reg1("C") end,
    { noremap = true, silent = true, desc = "Change to EOL -> reg 1 (preserve yank)" })
  vim.keymap.set("n", "x", function() op_to_reg1("x") end,
    { noremap = true, silent = true, desc = "x -> reg 1 (preserve yank)" })
  vim.keymap.set("n", "s", function() op_to_reg1("s") end,
    { noremap = true, silent = true, desc = "s -> reg 1 (preserve yank)" })

  -- Visual mode: reselect then operate so Vim handles all visual sub-modes
  vim.keymap.set("x", "d", function() op_to_reg1("d") end,
    { noremap = true, silent = true, desc = "V delete -> reg 1 (preserve yank)" })
  vim.keymap.set("x", "c", function() op_to_reg1("c") end,
    { noremap = true, silent = true, desc = "V change -> reg 1 (preserve yank)" })

  -- Visual paste: don't overwrite last yank with replaced text
  vim.keymap.set("x", "p", '"_dP', { noremap = true, silent = true, desc = "Visual paste (preserve yank)" })
end
