-- Set to false to disable PowerShell debugging
-- Disable this config file
local enabled = false

if not enabled then
  return {}
end
return {
  'mfussenegger/nvim-dap',
  optional = true,
  init = function()
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'ps1',
      once = true,
      callback = function()
        local dap = require 'dap'
        local mason_path = vim.fn.expand '~/.local/share/nvim/mason/packages/powershell-editor-services'
        local bundle_path = mason_path .. '/PowerShellEditorServices'
        local session_file = '/tmp/pes-session-' .. vim.fn.getpid() .. '.json'

        dap.adapters.powershell = function(cb)
          -- Clean up stale files
          vim.fn.delete(session_file)

          local handle
          handle = vim.uv.spawn('pwsh', {
            args = {
              '-NoLogo',
              '-NoProfile',
              bundle_path .. '/Start-EditorServices.ps1',
              '-BundledModulesPath',
              bundle_path,
              '-LogPath',
              '/tmp/pes.log',
              '-SessionDetailsPath',
              session_file,
              '-FeatureFlags',
              '@()',
              '-AdditionalModules',
              '@()',
              '-HostName',
              'nvim',
              '-HostProfileId',
              '0',
              '-HostVersion',
              '1.0.0',
              '-LogLevel',
              'Information',
            },
          }, function(_, _)
            if handle then
              handle:close()
            end
          end)

          -- Wait for session file and read the actual pipe name from it
          local timer = vim.uv.new_timer()
          if not timer then
            vim.notify('Failed to create timer', vim.log.levels.ERROR)
            return
          end
          local attempts = 0
          timer:start(2000, 1000, vim.schedule_wrap(function()
            attempts = attempts + 1
            local f = io.open(session_file, 'r')
            if f then
              local content = f:read '*a'
              f:close()
              if content and content:find 'PipeName' then
                local ok, session = pcall(vim.json.decode, content)
                if ok and session then
                  local pipe = session.debugServicePipeName
                  if not pipe or pipe == '' then
                    pipe = session.languageServicePipeName
                  end
                  if pipe and pipe ~= '' then
                    timer:stop()
                    timer:close()
                    vim.notify('PowerShell Editor Services started', vim.log.levels.INFO)
                    cb {
                      type = 'pipe',
                      pipe = pipe,
                    }
                    return
                  end
                end
              end
            end
            if attempts > 30 then
              timer:stop()
              timer:close()
              vim.notify('PowerShell Editor Services failed to start', vim.log.levels.ERROR)
            end
          end))
        end

        dap.configurations.ps1 = {
          {
            name = 'Launch PowerShell Script',
            type = 'powershell',
            request = 'launch',
            script = '${file}',
            cwd = '${workspaceFolder}',
            createTemporaryIntegratedConsole = true,
          },
        }
      end,
    })
  end,
}
