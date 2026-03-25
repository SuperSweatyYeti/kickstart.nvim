return {
  {
    'yetone/avante.nvim',
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    -- ⚠️ must add this setting! ! !
    build = is_os_windows() and 'powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false' or 'make',
    event = 'VeryLazy',
    version = false, -- Never set this value to "*"! Never!
    ---@module 'avante'
    ---@type avante.Config
    opts = {
      -- Modes: "legacy", "agentic"
      -- Switch to agentic to automatically apply changes without asking
      mode = 'legacy',
      -- Workflow
      -- Ask AI for changes. Shift + A to apply all diffs. Select which diffs to keep
      behaviour = {
        auto_approve_tool_permissions = true, -- Skip tool permission prompts; diffs are reviewed manually
        auto_apply_diff_after_generation = false, -- Show diffs in buffer for manual review
      },
      instructions_file = 'avante.md',
      provider = 'copilot',
      providers = {
        copilot = {
          endpoint = 'https://api.githubcopilot.com',
          model = 'gpt-4o',
          timeout = 30000,
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 20480,
          },
        },
        claude = {
          endpoint = 'https://api.anthropic.com',
          model = 'claude-sonnet-4-20250514',
          timeout = 30000,
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 20480,
          },
        },
        moonshot = {
          endpoint = 'https://api.moonshot.ai/v1',
          model = 'kimi-k2-0711-preview',
          timeout = 30000,
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 32768,
          },
        },
      },
    },

    config = function(_, opts)
      require('avante').setup(opts)

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'AvanteInput',
        callback = function(ev)
          local map_opts = { buffer = ev.buf, silent = true, noremap = true }

          vim.keymap.set('i', '<C-h>', '<C-\\><C-n><C-w>h', map_opts)
          vim.keymap.set('i', '<C-j>', '<C-\\><C-n><C-w>j', map_opts)
          vim.keymap.set('i', '<C-k>', '<C-\\><C-n><C-w>k', map_opts)
          vim.keymap.set('i', '<C-l>', '<C-\\><C-n><C-w>l', map_opts)
        end,
      })
    end,

    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-mini/mini.pick',
      'nvim-telescope/telescope.nvim',
      'hrsh7th/nvim-cmp',
      'ibhagwan/fzf-lua',
      'stevearc/dressing.nvim',
      'folke/snacks.nvim',
      'nvim-tree/nvim-web-devicons',
      'zbirenbaum/copilot.lua',
      {
        'HakonHarnes/img-clip.nvim',
        event = 'VeryLazy',
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            use_absolute_path = true,
          },
        },
      },
      {
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { 'markdown', 'Avante' },
        },
        ft = { 'markdown', 'Avante' },
      },
    },
  },
}
