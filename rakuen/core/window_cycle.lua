-- Pure helpers for the focus module: pick which window or app comes next.
--
-- Nothing here touches hs.*. The focus module collects window data and calls
-- these functions, so the ordering rules are unit testable.

local window_cycle = {}

local FORWARD = 1
local BACKWARD = -1

window_cycle.FORWARD = FORWARD
window_cycle.BACKWARD = BACKWARD

--- Return the id that follows `current_id` in ascending id order, wrapping around.
--- Ids are sorted so the order stays stable while focus moves. When `current_id`
--- is not in the list, forward picks the first id and backward the last.
--- Returns nil for an empty list.
function window_cycle.next_id(ids, current_id, step)
  assert(type(ids) == "table", "ids must be a table")
  assert(step == FORWARD or step == BACKWARD, "step must be FORWARD or BACKWARD")

  if #ids == 0 then
    return nil
  end

  local sorted = {}
  for _, id in ipairs(ids) do
    table.insert(sorted, id)
  end
  table.sort(sorted)

  local current_index = nil
  for index, id in ipairs(sorted) do
    if id == current_id then
      current_index = index
      break
    end
  end

  if current_index == nil then
    if step == FORWARD then
      return sorted[1]
    end
    return sorted[#sorted]
  end

  local target_index = (current_index - 1 + step) % #sorted + 1
  return sorted[target_index]
end

--- Pick the window to focus when switching applications.
--- `entries` is a front-to-back list of `{ app = <app id>, window = <window id> }`.
--- Forward returns the most recently used window of another app. Backward returns
--- the most recent window of the least recently used app. Returns nil when only
--- one app has windows.
function window_cycle.app_switch_target(entries, step)
  assert(type(entries) == "table", "entries must be a table")
  assert(step == FORWARD or step == BACKWARD, "step must be FORWARD or BACKWARD")

  if #entries == 0 then
    return nil
  end

  local front_app = entries[1].app

  if step == FORWARD then
    for _, entry in ipairs(entries) do
      if entry.app ~= front_app then
        return entry.window
      end
    end
    return nil
  end

  local last_app = entries[#entries].app
  if last_app == front_app then
    return nil
  end

  for _, entry in ipairs(entries) do
    if entry.app == last_app then
      return entry.window
    end
  end
  return nil
end

return window_cycle
