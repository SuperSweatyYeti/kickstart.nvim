return {
  {
    "ojroques/nvim-osc52",
    config = function()
      local osc52 = require("osc52")
      osc52.setup({
        max_length = 50000, -- 50KB limit
        trim = false, -- don't trim trailing newlines
        silent = false, -- show "n characters copied" message
      })

      -- Use OSC52 as the clipboard provider
      local function copy(lines, _)
        osc52.copy(table.concat(lines, "\n"))
      end

      local function paste()
        return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
      end

      vim.g.clipboard = {
        name = "osc52",
        copy = { ["+"] = copy, ["*"] = copy },
        paste = { ["+"] = paste, ["*"] = paste },
      }
    end,
  },
}
