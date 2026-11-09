-- lazy.nvim plugin spec, loaded automatically from lua/custom/plugins/
-- lua/custom/plugins/claude-code.lua
-- Claude Code integration: runs the `claude` CLI in a Neovim terminal and
-- speaks the same IDE protocol as the VS Code/JetBrains extensions, so Claude
-- can see your selection, open files, and propose edits as native diffs
return {
  {
    'coder/claudecode.nvim',
    -- snacks.nvim provides the floating/split terminal window Claude runs in
    dependencies = { 'folke/snacks.nvim' },
    -- Load at startup so the IDE websocket server is always running; with only
    -- `keys`, a `claude` started in another terminal finds no Neovim to connect to
    lazy = false,
    init = function()
      -- The plugin only reloads buffers whose name exactly matches the path Claude
      -- wrote, which misses files opened via the ~/.config/nvim symlink.
      -- :checktime compares the file on disk, so reload changed buffers ourselves
      vim.o.autoread = true
      vim.api.nvim_create_autocmd('User', {
        pattern = 'ClaudeCodeDiffClosed',
        callback = function()
          -- Wait for the CLI to finish writing the accepted edit
          vim.defer_fn(function() vim.cmd 'silent! checktime' end, 300)
        end,
      })
      -- Also catch edits Claude makes without a diff (e.g. auto-accepted)
      vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'TermLeave' }, {
        command = 'silent! checktime',
      })
    end,
    opts = {
      -- Render inline instead of on the alternate screen so output stays in the
      -- terminal buffer's scrollback (needed for gg/G/<C-u> in normal mode)
      env = { CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN = '1' },
      terminal = {
        -- Passed through to the snacks.nvim window that hosts the terminal
        snacks_win_opts = {
          keys = {
            -- Type JJ in terminal mode to drop to normal mode (<C-\><C-n>) so you
            -- can scroll, search, and yank Claude's output; <Esc> is left alone
            -- because Claude itself uses it to interrupt/cancel
            claude_escape = { 'JJ', '<C-\\><C-n>', mode = 't', expr = true, desc = 'Escape terminal mode' },
          },
        },
      },
      -- Proposed edits open as a side-by-side diff (original left, proposal right)
      -- in the window you're editing in. The proposal buffer is editable, so to
      -- reject a single hunk, jump to it with ]c/[c and pull the original back with
      -- `do` (:diffget). Accept what's left with :w (or <leader>aa), reject all with <leader>ad
      diff_opts = {
        layout = 'vertical',
        open_in_new_tab = false, -- show the diff where you are instead of a separate tab
        keep_terminal_focus = false, -- jump into the diff so you can review it
      },
    },
    -- All mappings live under <leader>a ("AI")
    keys = {
      -- Session management
      { '<leader>act', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude' },
      { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'Focus Claude' },
      { '<leader>ar', '<cmd>ClaudeCode --resume<cr>', desc = 'Resume Claude session' }, -- pick a past conversation to continue
      -- Sharing context: @-mention the whole file, or send just the visual selection
      { '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Add current buffer to Claude' },
      { '<leader>as', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'Send selection' },
      -- Reviewing proposed edits (run from inside the diff tab)
      { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Accept diff' },
      { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Reject diff' },
    },
  },
}
-- Requires the `claude` CLI on $PATH (run `:checkhealth claudecode` if it fails to start)
-- Docs and full option list: https://github.com/coder/claudecode.nvim
-- diffopt tweaks (word-level inline diff, linematch) live in lua/custom/settings/diff-settings.lua
-- Run :ClaudeCodeStatus to check whether a `claude` session is connected to this Neovim
-- vim: ts=2 sts=2 sw=2 et
-- End of claude-code.lua