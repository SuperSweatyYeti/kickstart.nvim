return {
  'mfussenegger/nvim-dap-python',
  dependencies = { 'mfussenegger/nvim-dap' },
  config = function()
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
  end,
}
