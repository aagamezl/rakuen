local function mergeObjects(...)
  local result = {}
  local lists = table.pack(...)

  for i = 1, lists.n do
    local list = lists[i]

    if list then
      for _, remap in ipairs(list) do
        table.insert(result, remap)
      end
    end
  end

  return result
end

return mergeObjects