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

--- Every bundle id either filter lists in `enable`; the only apps that can matter
--- when at least one filter is not open to all.
local function listed_apps(first, second)
  local apps = {}

  for _, filter in ipairs({ first, second }) do
    for _, bundle_id in ipairs(filter.enable or {}) do
      table.insert(apps, bundle_id)
    end
  end

  return apps
end

--- Return true when some application exists where both filters allow a rule.
--- Used by the registry to detect two rules that claim the same chord.
function app_filter.overlaps(first, second)
  local first_filter = first or {}
  local second_filter = second or {}

  if is_empty(first_filter.enable) and is_empty(second_filter.enable) then
    return true
  end

  -- At least one side lists apps explicitly: check each listed app against both filters.
  for _, bundle_id in ipairs(listed_apps(first_filter, second_filter)) do
    local allowed_by_first = app_filter.allows(first_filter, bundle_id)
    local allowed_by_second = app_filter.allows(second_filter, bundle_id)
    if allowed_by_first and allowed_by_second then
      return true
    end
  end

  return false
end

return app_filter
