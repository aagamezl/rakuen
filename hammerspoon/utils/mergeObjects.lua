local function mergeObjects(...)
  local result = {}

  for _, list in ipairs({ ... }) do
    for _, remap in ipairs(list) do
      table.insert(result, remap)
    end
  end

  return result
end

return mergeObjects