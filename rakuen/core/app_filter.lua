-- Decide whether a rule applies to an application (design decision D4).
--
-- A filter is { enable = { bundle ids }, disable = { bundle ids } }.
-- An empty or missing `enable` list means every application.
-- `disable` always wins over `enable`.

local app_filter = {}

local function to_set(list)
  local set = {}
  for _, bundle_id in ipairs(list or {}) do
    set[bundle_id] = true
  end
  return set
end

local function is_empty(list)
  return list == nil or #list == 0
end

--- Return true when a rule with `applications` may run in `bundle_id`.
--- `bundle_id` may be nil when no application is frontmost.
function app_filter.allows(applications, bundle_id)
  local filter = applications or {}

  if bundle_id ~= nil and to_set(filter.disable)[bundle_id] then
    return false
  end

  if is_empty(filter.enable) then
    return true
  end

  return bundle_id ~= nil and to_set(filter.enable)[bundle_id] == true
end

--- Return true when some application exists where both filters allow a rule.
--- Used by the registry to detect two rules that claim the same chord.
function app_filter.overlaps(first, second)
  local first_filter = first or {}
  local second_filter = second or {}

  local first_open = is_empty(first_filter.enable)
  local second_open = is_empty(second_filter.enable)

  if first_open and second_open then
    return true
  end

  -- At least one side lists apps explicitly: check each listed app against both filters.
  local candidates = {}
  for _, bundle_id in ipairs(first_filter.enable or {}) do
    table.insert(candidates, bundle_id)
  end
  for _, bundle_id in ipairs(second_filter.enable or {}) do
    table.insert(candidates, bundle_id)
  end

  for _, bundle_id in ipairs(candidates) do
    if
      app_filter.allows(first_filter, bundle_id) and app_filter.allows(second_filter, bundle_id)
    then
      return true
    end
  end

  return false
end

return app_filter
