return {
  {
    'mfussenegger/nvim-dap',
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'sh', 'bash' },
        once = true,
        callback = function()
          local dap = require 'dap'

          dap.adapters.bash = {
            type = 'executable',
            command = vim.fn.exepath 'bash-debug-adapter',
          }

          local BASHDB_DIR = vim.fn.expand '$MASON/opt/bashdb'

          local bash_config = {
            {
              name = 'Bash: Launch file',
              type = 'bash',
              request = 'launch',
              program = '${file}',
              cwd = '${fileDirname}',
              pathBashdb = BASHDB_DIR .. '/bashdb',
              pathBashdbLib = BASHDB_DIR,
              pathBash = 'bash',
              pathCat = 'cat',
              pathMkfifo = 'mkfifo',
              pathPkill = 'pkill',
              env = {},
              args = {},
              terminalKind = 'integrated',
            },
          }

          dap.configurations.sh = bash_config
          dap.configurations.bash = bash_config
        end,
      })
    end,
  },
}
