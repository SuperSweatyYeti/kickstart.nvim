local enabled = true

if not enabled then
  return {}
end

return {
  'mfussenegger/nvim-dap-python',
  dependencies = { 'mfussenegger/nvim-dap' },
  config = function()
    -- Config for Linux
    if is_os_linux() then
      local python = vim.fn.expand '~/.local/share/nvim/mason/packages/debugpy/venv/bin/python'
      require('dap-python').setup(python)

      -- Auto-detect project venv and set pythonPath on all Python DAP configs
      local cwd = vim.fn.getcwd()
      local candidates = {
        os.getenv 'VIRTUAL_ENV' and (os.getenv 'VIRTUAL_ENV' .. '/bin/python') or nil,
        cwd .. '/.venv/bin/python',
        cwd .. '/venv/bin/python',
        cwd .. '/env/bin/python',
        cwd .. '/.env/bin/python',
      }

      local venv_python = nil
      for _, candidate in ipairs(candidates) do
        if vim.fn.executable(candidate) == 1 then
          venv_python = candidate
          break
        end
      end

      if venv_python then
        for _, config in ipairs(require('dap').configurations.python) do
          config.pythonPath = venv_python
        end
      end
    end

    -- Config for Windows
    if is_os_windows() then
      local python = vim.fn.expand '~/AppData/Local/nvim-data/mason/packages/debugpy/venv/Scripts/python.exe'
      require('dap-python').setup(python)

      -- Prevent the blank console window by keeping the adapter process
      -- attached to Neovim's console instead of allocating a new one.
      local dap = require('dap')
      local original_adapter = dap.adapters.python
      dap.adapters.python = function(cb, config)
        original_adapter(function(adapter)
          adapter.options = adapter.options or {}
          adapter.options.detached = false
          cb(adapter)
        end, config)
      end

      -- Auto-detect project venv and set pythonPath on all Python DAP configs
      local cwd = vim.fn.getcwd()
      local candidates = {
        os.getenv 'VIRTUAL_ENV' and (os.getenv 'VIRTUAL_ENV' .. '/Scripts/python.exe') or nil,
        cwd .. '/.venv/Scripts/python.exe',
        cwd .. '/venv/Scripts/python.exe',
        cwd .. '/env/Scripts/python.exe',
        cwd .. '/.env/Scripts/python.exe',
      }

      local venv_python = nil
      for _, candidate in ipairs(candidates) do
        if vim.fn.executable(candidate) == 1 then
          venv_python = candidate
          break
        end
      end

      if venv_python then
        for _, config in ipairs(dap.configurations.python) do
          config.pythonPath = venv_python
        end
      end

      -- Use internal console to prevent a blank terminal window from opening
      for _, config in ipairs(dap.configurations.python) do
        config.console = 'internalConsole'
      end
    end
  end,
}
