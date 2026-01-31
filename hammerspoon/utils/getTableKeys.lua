--- Returns the keys of a table
--- @param target table The table to get the keys from
--- @return table The keys of the table
local function getTableKeys(target)
  local keys = {}

  for key, _ in pairs(target) do
    table.insert(keys, key)
  end

  return keys
end

return getTableKeys