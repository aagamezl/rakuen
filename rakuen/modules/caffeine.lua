-- Caffeine module: keep the Mac awake while the toggle is on.
--
-- A menu bar cup shows the state (filled with steam: awake). Click it, or press
-- the chord, to toggle. It holds the display awake with `hs.caffeinate`, which
-- also stops the system from idle sleeping. Reloading Hammerspoon ends it, and
-- so does turning the toggle off. GNOME has no default for this (it ships as an
-- extension), so the chord is Rakuen's own.

local caffeine_icon = require("rakuen.ui.caffeine_icon")
local deferred = require("rakuen.core.deferred")

local caffeine = {}

local RULE_NAME = "Toggle Caffeine"
local ASSERTION = "displayIdle"
local TITLE_ON = "Caffeine: Awake"
local TITLE_OFF = "Caffeine: Off"
local TOOLTIP_ON = "Caffeine is on. Click to let the Mac sleep"
local TOOLTIP_OFF = "Caffeine is off. Click to keep the Mac awake"

local menu_item = nil

--- Text for the state, used in the alert and when the icon cannot be drawn.
function caffeine.title(active)
  if active then
    return TITLE_ON
  end
  return TITLE_OFF
end

--- Hover text for the state.
function caffeine.tooltip(active)
  if active then
    return TOOLTIP_ON
  end
  return TOOLTIP_OFF
end

local function is_active()
  return hs.caffeinate.get(ASSERTION) == true
end

local function refresh()
  if menu_item == nil then
    return
  end

  local active = is_active()
  local image = caffeine_icon.image(active)

  if image ~= nil then
    menu_item:setIcon(image, false)
    menu_item:setTitle("")
  else
    menu_item:setIcon(nil)
    menu_item:setTitle(caffeine.title(active))
  end

  menu_item:setTooltip(caffeine.tooltip(active))
end

--- Flip the state, update the menu bar and return the new state.
function caffeine.toggle()
  local active = not is_active()
  hs.caffeinate.set(ASSERTION, active, true)
  refresh()
  return active
end

local function toggle_with_alert()
  local active = caffeine.toggle()
  hs.alert.show(caffeine.title(active))
end

caffeine.rules = {
  {
    description = RULE_NAME,
    from = "none",
    to = "Ctrl+Cmd+K",
    action = deferred.guard(toggle_with_alert),
    feasibility = "yes",
    note = "Keeps the Mac and display awake. The menu bar cup shows the state and also toggles",
  },
}

local function has_rule(rules)
  for _, rule in ipairs(rules) do
    if rule.description == RULE_NAME then
      return true
    end
  end
  return false
end

--- Add the menu bar cup. Skipped when the binding is disabled in the config.
function caffeine.on_load(_, rules)
  if not has_rule(rules) then
    return
  end

  menu_item = hs.menubar.new()
  menu_item:setClickCallback(function()
    local succeeded, toggle_error = pcall(caffeine.toggle)
    if not succeeded then
      hs.alert.show("Rakuen: " .. tostring(toggle_error))
    end
  end)
  -- Start awake, as the old version did, instead of keeping whatever state was left.
  hs.caffeinate.set(ASSERTION, true, true)
  refresh()
end

return caffeine
