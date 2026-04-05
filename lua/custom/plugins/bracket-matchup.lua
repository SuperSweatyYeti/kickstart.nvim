return {
  {
    'andymass/vim-matchup',
    enabled = true,
    config = function()
      -- vim.g.matchup_matchparen_offscreen = { method = 'popup' }

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'markdown' },
        callback = function()
          vim.keymap.set('n', '%', function()
            local current_line = vim.api.nvim_win_get_cursor(0)[1]
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

            -- only do custom logic if we're on a fence line
            if not lines[current_line]:match('^```') then
              -- fall back to normal matchup
              vim.cmd('normal! %')
              return
            end

            -- count fences above current line to determine if open or close
            local fence_count = 0
            for i = 1, current_line - 1 do
              if lines[i]:match('^```') then
                fence_count = fence_count + 1
              end
            end

            local is_opening = fence_count % 2 == 0

            if is_opening then
              -- search forward for closing ```
              for i = current_line + 1, #lines do
                if lines[i]:match('^```$') then
                  vim.api.nvim_win_set_cursor(0, { i, 0 })
                  return
                end
              end
            else
              -- search backward for opening ```
              for i = current_line - 1, 1, -1 do
                if lines[i]:match('^```') then
                  vim.api.nvim_win_set_cursor(0, { i, 0 })
                  return
                end
              end
            end
          end, { buffer = true, desc = 'matchup % with markdown fences' })
        end,
      })
    end,
  },
}
