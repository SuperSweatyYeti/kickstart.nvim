-- Diff mode tweaks (affects :diffsplit, fugitive, and claudecode.nvim's diff tab)
-- Neovim 0.12 defaults to inline:char and linematch:40

-- Highlight changed words within a line instead of individual characters;
-- inline:* values are exclusive, so drop the default before adding ours
vim.opt.diffopt:remove('inline:char')
vim.opt.diffopt:append('inline:word')

-- Align similar lines inside larger changed hunks (default limit is 40 lines)
vim.opt.diffopt:remove('linematch:40')
vim.opt.diffopt:append('linematch:60')
