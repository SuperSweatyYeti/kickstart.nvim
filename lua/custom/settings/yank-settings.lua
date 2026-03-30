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
  vim.keymap.set({ "n", "x" }, "<Leader>p", "<cmd>YankyRingHistory<CR>", { silent = true, desc = "Yanky history" })
  vim.keymap.set("n", "<c-n>", "<Plug>(YankyCycleForward)", {})
  vim.keymap.set("n", "<c-p>", "<Plug>(YankyCycleBackward)", {})
end

------------------------------------------------------------
-- 3) Preserve last yank for p/P, but keep deletes accessible in register "1
------------------------------------------------------------
do
  -- Normal mode: route destructive operators to register 1.
  vim.keymap.set("n", "d", '"1d', { noremap = true, silent = true, desc = "Delete -> reg 1 (preserve yank)" })
  vim.keymap.set("n", "c", '"1c', { noremap = true, silent = true, desc = "Change -> reg 1 (preserve yank)" })
  vim.keymap.set("n", "x", '"1x', { noremap = true, silent = true, desc = "x -> reg 1 (preserve yank)" })
  vim.keymap.set("n", "s", '"1s', { noremap = true, silent = true, desc = "s -> reg 1 (preserve yank)" })

  -- Visual paste: don't overwrite last yank with replaced text
  vim.keymap.set("x", "p", '"_dP', { noremap = true, silent = true, desc = "Visual paste (preserve yank)" })

  local function normalize_visual_points()
    local vpos = vim.fn.getpos("v")
    local cpos = vim.fn.getpos(".")
    local srow, scol = vpos[2], vpos[3]
    local erow, ecol = cpos[2], cpos[3]

    if (erow < srow) or (erow == srow and ecol < scol) then
      srow, erow = erow, srow
      scol, ecol = ecol, scol
    end

    -- convert to 0-indexed
    return (srow - 1), (scol - 1), (erow - 1), (ecol - 1)
  end

  local function clamp_col(buf, row0, col0)
    local line = vim.api.nvim_buf_get_lines(buf, row0, row0 + 1, true)[1] or ""
    local maxc = #line
    if col0 < 0 then
      return 0
    end
    if col0 > maxc then
      return maxc
    end
    return col0
  end

  local function visual_delete_or_change(op) -- op = "d" or "c"
    return function()
      local mode = vim.fn.visualmode() -- 'v', 'V', or CTRL-V
      if mode == "\022" then
        vim.notify("[yank-settings] Visual block mode not supported by this mapping yet", vim.log.levels.WARN)
        return
      end

      local buf = 0
      local srow, scol, erow, ecol = normalize_visual_points()

      if mode == "V" then
        -- Linewise: store selected lines into reg 1, then delete via set_lines (safe)
        local lines = vim.api.nvim_buf_get_lines(buf, srow, erow + 1, true)
        vim.fn.setreg("1", table.concat(lines, "\n") .. "\n", "V") -- linewise register

        vim.api.nvim_buf_set_lines(buf, srow, erow + 1, true, {})

        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
        if op == "c" then
          vim.api.nvim_win_set_cursor(0, { srow + 1, 0 })
          vim.api.nvim_feedkeys("i", "n", false)
        end
        return
      end

      -- Characterwise: clamp columns to line bounds
      scol = clamp_col(buf, srow, scol)
      ecol = clamp_col(buf, erow, ecol)

      -- In charwise visual, the end is inclusive; API expects end-exclusive
      local end_excl = clamp_col(buf, erow, ecol + 1)

      -- Get selected text, store in reg 1
      local text = vim.api.nvim_buf_get_text(buf, srow, scol, erow, end_excl, {})
      vim.fn.setreg("1", table.concat(text, "\n"), "v")

      -- Delete selection without touching unnamed/clipboard
      vim.api.nvim_buf_set_text(buf, srow, scol, erow, end_excl, { "" })

      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
      if op == "c" then
        vim.api.nvim_win_set_cursor(0, { srow + 1, scol })
        vim.api.nvim_feedkeys("i", "n", false)
      end
    end
  end

  vim.keymap.set("x", "d", visual_delete_or_change("d"), { noremap = true, silent = true, desc = "V delete -> reg 1 (preserve yank)" })
  vim.keymap.set("x", "c", visual_delete_or_change("c"), { noremap = true, silent = true, desc = "V change -> reg 1 (preserve yank)" })
end
