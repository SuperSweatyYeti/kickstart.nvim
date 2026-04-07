-- Nice shorthand to print table contents
P = function(x, max)
  if max and type(x) == 'table' then
    local trimmed = {}
    local count = 0
    for k, v in pairs(x) do
      if count >= max then break end
      trimmed[k] = v
      count = count + 1
    end
    print(vim.inspect(trimmed) .. '\n... (' .. (vim.tbl_count(x) - max) .. ' more)')
  else
    print(vim.inspect(x))
  end
end
