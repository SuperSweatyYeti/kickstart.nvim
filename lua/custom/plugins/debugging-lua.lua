-- debugging-lua.lua
--
-- Lua DAP adapter + configuration using local-lua-debugger-vscode (Mason).
-- Core DAP setup (dapui, keymaps, signs, listeners) lives in debugging.lua.
-- This file only registers the adapter and dap.configurations.lua.
--
-- Uses 'init' instead of 'config' so lazy.nvim does NOT merge or re-run
-- the nvim-dap config function from debugging.lua.

-- Set to false to disable Lua debugging
local enabled = false

if not enabled then
  return {}
end

return {
  'mfussenegger/nvim-dap',
  optional = true,
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'lua',
      once = true,
      callback = function()
        local ok, dap = pcall(require, 'dap')
        if not ok then
          return
        end

        -- NOTE: Mason unpacks the .vsix with an extra 'extension/' nesting layer:
        -- .../packages/local-lua-debugger-vscode/extension/extension/debugAdapter.js
        local mason_pkg = vim.fn.stdpath 'data' .. '/mason/packages/local-lua-debugger-vscode/extension/extension'

        -- [[ Adapter ]]
        -- local-lua-debugger-vscode runs on Node.js.
        -- NOTE: 'node' must be available in $PATH.
        dap.adapters['local-lua'] = {
          type = 'executable',
          command = 'node',
          args = {
            mason_pkg .. '/debugAdapter.js',
          },
          enrich_config = function(config, on_config)
            if not config['extensionPath'] then
              local c = vim.deepcopy(config)
              c.extensionPath = mason_pkg .. '/'
              on_config(c)
            else
              on_config(config)
            end
          end,
        }

        -- [[ Configurations ]]
        dap.configurations.lua = {
          {
            type = 'local-lua',
            request = 'launch',
            name = 'Debug current file (lua)',
            cwd = '${workspaceFolder}',
            program = {
              lua = 'lua',
              file = '${file}',
            },
            args = {},
            stopOnEntry = false,
          },
          {
            -- Requires nlua (:MasonInstall nlua) for vim.* API support
            type = 'local-lua',
            request = 'launch',
            name = 'Debug current file (luajit / neovim)',
            cwd = '${workspaceFolder}',
            program = {
              lua = 'nlua',
              file = '${file}',
            },
            args = {},
            stopOnEntry = false,
          },
        }
      end,
    })
  end,
}
