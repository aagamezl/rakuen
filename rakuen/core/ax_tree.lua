-- Search an accessibility element tree. Works on any object with
-- `attributeValue(name)`, so tests can use fakes. Nothing here needs hs.*.

local ax_tree = {}

local MAX_DEPTH = 12

--- Depth-first search for the first element where `predicate(element)` is true.
function ax_tree.find_matching(element, predicate, depth)
  depth = depth or 0
  if element == nil or depth > MAX_DEPTH then
    return nil
  end

  if predicate(element) then
    return element
  end

  for _, child in ipairs(element:attributeValue("AXChildren") or {}) do
    local found = ax_tree.find_matching(child, predicate, depth + 1)
    if found ~= nil then
      return found
    end
  end
  return nil
end

--- Depth-first search for the element whose AXIdentifier is `identifier`.
function ax_tree.find_element(element, identifier)
  return ax_tree.find_matching(element, function(candidate)
    return candidate:attributeValue("AXIdentifier") == identifier
  end)
end

--- Every element whose AXIdentifier is `identifier`, depth first.
function ax_tree.find_elements(element, identifier, results, depth)
  results = results or {}
  depth = depth or 0
  if element == nil or depth > MAX_DEPTH then
    return results
  end

  if element:attributeValue("AXIdentifier") == identifier then
    table.insert(results, element)
  end
  for _, child in ipairs(element:attributeValue("AXChildren") or {}) do
    ax_tree.find_elements(child, identifier, results, depth + 1)
  end
  return results
end

return ax_tree
