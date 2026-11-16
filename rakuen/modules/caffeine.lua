-- Caffeine module: keep the Mac awake while the toggle is on.
--
-- The shared Rakuen menu bar item shows a cup (filled with steam: awake). Its menu
-- has a Caffeine entry, and the chord toggles too. It holds the display awake
-- with `hs.caffeinate`, which also stops the system from idle sleeping.
-- Reloading Hammerspoon ends it, and so does turning the toggle off.
-- GNOME has no default for this (it ships as an extension), so the chord is
-- Rakuen's own.

local caffeine_icon = require("rakuen.ui.caffeine_icon")
local deferred = require("rakuen.core.deferred")
local menubar = require("rakuen.ui.menubar")

local caffeine = {}

local RULE_NAME = "Toggle Caffeine"
local ASSERTION = "displayIdle"
local TITLE_ON = "Caffeine: Awake"
local TITLE_OFF = "Caffeine: Off"
local TOOLTIP_ON = "Caffeine is on. Turn it off from the menu to let the Mac sleep"
local TOOLTIP_OFF = "Caffeine is off. Turn it on from the menu to keep the Mac awake"

-- The menu bar shows only the Rakuen title. Set this to true to draw the cup beside it.
local SHOW_MENU_ICON = false

local loaded = false

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
  if not loaded then
    return
  end

  local active = is_active()
  local image = nil
  if SHOW_MENU_ICON then
    image = caffeine_icon.image(active)
  end
  menubar.set_appearance(image, "Rakuen. " .. caffeine.tooltip(active))
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
    note = "Keeps the Mac and display awake. The menu bar cup shows the state, its menu toggles",
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

--- Add the cup and the menu entry. Skipped when the binding is disabled in the config.
function caffeine.on_load(_, rules)
  if not has_rule(rules) then
    return
  end

  loaded = true
  menubar.add_section("caffeine", function()
    return {
      {
        title = "Caffeine",
        image = caffeine_icon.image(is_active(), true),
        checked = is_active(),
        fn = function()
          local succeeded, toggle_error = pcall(caffeine.toggle)
          if not succeeded then
            hs.alert.show("Rakuen: " .. tostring(toggle_error))
          end
        end,
      },
    }
  end)
  -- Start awake, as the old version did, instead of keeping whatever state was left.
  hs.caffeinate.set(ASSERTION, true, true)
  refresh()
end

return caffeine
