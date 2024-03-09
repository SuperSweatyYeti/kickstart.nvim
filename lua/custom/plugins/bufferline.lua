return {
  -- Show Buffers in Tabs at the top of the screen
  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {
      options = {

        -- custom_filter = function(buf_number, buf_numbers)
        --   if buf_numbers[1] ~= buf_number then
        --     -- filter out by it's index number in list (don't show first buffer)
        --     return true
        --   end
        -- end,
        offsets = {
          filetype = 'NeoTree',
          text = 'File Explorer',
          text_align = 'left',
          separator = true,
          always_show_bufferline = false,
        },
      },
    },
  },
}
