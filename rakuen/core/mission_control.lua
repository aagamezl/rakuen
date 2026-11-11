-- Drive Mission Control through accessibility.
--
-- Since macOS 27 the controls live in the WindowManager process, not the
-- Dock, so hs.spaces.addSpaceToScreen and removeSpace fail with "Unable to get
-- mission control data from the dock". Rakuen opens Mission Control, finds the
-- control by its accessibility identifier, and presses it. hs.spaces.
-- closeMissionControl fails the same way, so Mission Control is closed with
-- Escape.

local synthetic = require("rakuen.core.synthetic")

local mission_control = {}

mission_control.WINDOW_MANAGER_BUNDLE_ID = "com.apple.WindowManager"
mission_control.ADD_BUTTON_ID = "mc.spaces.add"
mission_control.DISPLAY_ID = "mc.display"
mission_control.SPACES_LIST_ID = "mc.spaces.list"

local MAX_DEPTH = 12
local POLL_SECONDS = 0.2
local OPEN_TIMEOUT_SECONDS = 3
local CLOSE_DELAY_SECONDS = 0.5

--- Depth-first search for the element whose AXIdentifier is `identifier`.
--- Works on any object with `attributeValue(name)`, so tests can fake it.
function mission_control.find_element(element, identifier, depth)
  depth = depth or 0
  if element == nil or depth > MAX_DEPTH then
    return nil
  end

  if element:attributeValue("AXIdentifier") == identifier then
    return element
  end

  for _, child in ipairs(element:attributeValue("AXChildren") or {}) do
    local found = mission_control.find_element(child, identifier, depth + 1)
    if found ~= nil then
      return found
    end
  end
  return nil
end

--- Every element whose AXIdentifier is `identifier`, depth first.
function mission_control.find_elements(element, identifier, results, depth)
  results = results or {}
  depth = depth or 0
  if element == nil or depth > MAX_DEPTH then
    return results
  end

  if element:attributeValue("AXIdentifier") == identifier then
    table.insert(results, element)
  end
  for _, child in ipairs(element:attributeValue("AXChildren") or {}) do
    mission_control.find_elements(child, identifier, results, depth + 1)
  end
  return results
end

--- Choose the Mission Control display for `display_id`; with a single
--- display, that one whatever its id.
function mission_control.pick_display(displays, display_id)
  for _, display in ipairs(displays) do
    if display:attributeValue("AXDisplayID") == display_id then
      return display
    end
  end
  if #displays == 1 then
    return displays[1]
  end
  return nil
end

--- The Space thumbnail at `space_index` (position in hs.spaces order) on the
--- display `display_id`, or nil when Mission Control has not drawn it yet.
function mission_control.find_space_element(root, display_id, space_index)
  local displays = mission_control.find_elements(root, mission_control.DISPLAY_ID)
  local display = mission_control.pick_display(displays, display_id)
  if display == nil then
    return nil
  end

  local list = mission_control.find_element(display, mission_control.SPACES_LIST_ID)
  if list == nil then
    return nil
  end
  return (list:attributeValue("AXChildren") or {})[space_index]
end

local function window_manager_root()
  local apps = hs.application.applicationsForBundleID(mission_control.WINDOW_MANAGER_BUNDLE_ID)
  local app = apps[1]
  if app == nil then
    return nil
  end
  return hs.axuielement.applicationElementForPID(app:pid())
end

local function open()
  if hs.spaces.openMissionControl ~= nil then
    hs.spaces.openMissionControl()
    return
  end
  hs.spaces.toggleMissionControl()
end

--- Close Mission Control. Escape is used because the Dock-based close fails.
function mission_control.close()
  synthetic.post_key({}, "escape")
end

--- Wait until `find(root)` returns an element, then call `callback(element)`;
--- `callback(nil)` when it does not show up in time.
local function wait_for_element(find, callback, waited)
  waited = waited or 0
  local root = window_manager_root()
  local element = nil
  if root ~= nil then
    element = find(root)
  end

  if element ~= nil or waited >= OPEN_TIMEOUT_SECONDS then
    callback(element)
    return
  end

  hs.timer.doAfter(POLL_SECONDS, function()
    wait_for_element(find, callback, waited + POLL_SECONDS)
  end)
end

--- Open Mission Control, perform `action` on the element `find` locates, then
--- close Mission Control. `on_done(true)` or `on_done(false, message)`.
local function press(find, action, label, on_done)
  open()
  wait_for_element(find, function(element)
    if element == nil then
      mission_control.close()
      on_done(false, label .. " not found in Mission Control")
      return
    end

    local succeeded, result, press_error = pcall(function()
      return element:performAction(action)
    end)

    hs.timer.doAfter(CLOSE_DELAY_SECONDS, function()
      mission_control.close()
      if not succeeded then
        on_done(false, result)
      elseif not result then
        on_done(false, press_error or "action failed")
      else
        on_done(true)
      end
    end)
  end)
end

--- Add a Space at the end of the current display.
function mission_control.add_space(on_done)
  press(function(root)
    return mission_control.find_element(root, mission_control.ADD_BUTTON_ID)
  end, "AXPress", "Add Space button", on_done)
end

--- Remove the Space at `space_index` (its position in hs.spaces.spacesForScreen)
--- on the display `display_id`. The Space must not be the active one.
function mission_control.remove_space(display_id, space_index, on_done)
  press(function(root)
    return mission_control.find_space_element(root, display_id, space_index)
  end, "AXRemoveDesktop", "Space", on_done)
end

return mission_control
