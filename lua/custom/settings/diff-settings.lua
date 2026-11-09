-- Diff mode tweaks (affects :diffsplit, fugitive, and claudecode.nvim's diff tab)
-- Neovim 0.12 defaults to inline:char and linematch:40

-- Highlight changed words within a line instead of individual characters;
-- inline:* values are exclusive, so drop the default before adding ours
vim.opt.diffopt:remove('inline:char')
vim.opt.diffopt:append('inline:word')

-- Align similar lines inside larger changed hunks (default limit is 40 lines)
vim.opt.diffopt:remove('linematch:40')
vim.opt.diffopt:append('linematch:60')

-- Default diff-mode keybinds (built into Neovim, no plugin needed):
--   ]c          jump to the start of the next hunk
--   [c          jump to the start of the previous hunk
--   do          "diff obtain": pull the other window's version of this hunk into
--               the current buffer (:diffget) -- i.e. accept their change here
--   dp          "diff put": push this buffer's version of the hunk into the other
--               window (:diffput) -- i.e. overwrite their side with yours
--   :diffget / :diffput accept a range, e.g. :'<,'>diffget for a visual selection
--   :diffupdate re-scan the buffers if the highlighting gets out of sync
-- There's no separate "reject": leaving a hunk alone keeps the current buffer's
-- version, and `u` undoes a do/dp. Counts work too, e.g. 3]c skips three hunks.
