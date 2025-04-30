-- Ensure plenary is available
local plenary_ok, scan = pcall(require, "plenary.scandir")
if not plenary_ok then
  vim.notify("[custom.settings] plenary.nvim is required", vim.log.levels.ERROR)
  return
end

-- Scan the 'custom/settings' folder
local settings_dir = vim.fn.stdpath("config") .. "/lua/custom/settings"
local files = scan.scan_dir(settings_dir, { depth = 1, add_dirs = false })

-- Iterate over each .lua file in the folder and require it
for _, file in ipairs(files) do
  if file:match("%.lua$") and not file:match("init.lua$") then
    local module = file
      :gsub(vim.fn.stdpath("config") .. "/lua/", "")  -- Remove the base path
      :gsub("%.lua$", "")                             -- Remove .lua extension
      :gsub("/", ".")                                 -- Convert to Lua module format
    require(module)
  end
end

