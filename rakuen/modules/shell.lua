-- Shell module: GNOME Shell actions on macOS equivalents.
--
-- Cmd acts as GNOME Super and Opt as Alt (design decision D1). macOS has no
-- Overview, and switching Spaces is left to macOS (see the workspaces module),
-- so overview up/down have no rule. Quick settings and the message tray are
-- partial: System Settings opens, and the Notification Center status item is
-- clicked through accessibility, which can move between macOS versions.

local ax_tree = require("rakuen.core.ax_tree")
local deferred = require("rakuen.core.deferred")
local screens = require("rakuen.core.screens")
local screenshot = require("rakuen.core.screenshot")

local shell = {}

-- Apps shown by the application grid: Launchpad was replaced by Apps in macOS 26.
local APPLICATION_GRID_APPS = { "Apps", "Launchpad" }
local SETTINGS_APP = "System Settings"
-- The process that owns the menu bar items, and the clock item's identifier.
local MENU_BAR_BUNDLE_ID = "com.apple.MenuBarAgent"
local NOTIFICATION_ITEM_ID = "com.apple.menuextra.clock"
-- Seconds to leave the pointer on the clock before putting it back.
local POINTER_RESTORE_DELAY = 0.3
-- Seconds between the mouse press and release of the click.
local CLICK_HOLD = 0.05

local function key_action(mods, key)
  return { mods = mods, key = key }
end

local function open_application_grid()
  for _, name in ipairs(APPLICATION_GRID_APPS) do
    if hs.application.launchOrFocus(name) then
      return
    end
  end
  hs.alert.show("Rakuen: no application grid found (Apps or Launchpad)")
end

local function open_quick_settings()
  if not hs.application.launchOrFocus(SETTINGS_APP) then
    hs.alert.show("Rakuen: could not open " .. SETTINGS_APP)
  end
end

local function center_of(frame)
  return frame.x + frame.w / 2, frame.y + frame.h / 2
end

local function contains_point(area, x, y)
  return x >= area.x and x < area.x + area.w and y >= area.y and y < area.y + area.h
end

--- Choose the item whose AXFrame lies on the display `screen_frame`, so
--- Notification Center opens where the user is working. With no match (for
--- example one clock for all displays) the first item is used.
function shell.pick_item_for_screen(items, screen_frame)
  for _, item in ipairs(items) do
    local frame = item:attributeValue("AXFrame")
    if frame ~= nil then
      local x, y = center_of(frame)
      if contains_point(screen_frame, x, y) then
        return item
      end
    end
  end
  return items[1]
end

--- Find the clock items, which open Notification Center. On macOS 27 the menu
--- bar items belong to MenuBarAgent and hang off its AXExtrasMenuBar attribute
--- (not AXChildren), as found with scripts/spikes/menu_bar_dump.lua.
function shell.find_notification_items(app_element)
  local extras = app_element:attributeValue("AXExtrasMenuBar")
  if extras == nil then
    return {}
  end
  return ax_tree.find_elements(extras, NOTIFICATION_ITEM_ID)
end

--- Open the item like a user would, with a real click on it, then put the
--- pointer back. The accessibility press opened Notification Center for a
--- moment only; a click keeps it open. Without a frame, fall back to the press.
local function press_item(item)
  local frame = item:attributeValue("AXFrame")
  if frame == nil then
    item:performAction("AXPress")
    return
  end

  local x, y = center_of(frame)
  local point = { x = x, y = y }
  local original = hs.mouse.absolutePosition()

  -- Press and release as two events; hs.eventtap.leftClick would block.
  hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, point):post()
  hs.timer.doAfter(CLICK_HOLD, function()
    hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, point):post()
  end)
  hs.timer.doAfter(POINTER_RESTORE_DELAY, function()
    hs.mouse.absolutePosition(original)
  end)
end

local function toggle_message_tray()
  local app = hs.application.get(MENU_BAR_BUNDLE_ID)
  if app == nil then
    hs.alert.show("Rakuen: the menu bar agent is not running")
    return
  end

  local items = shell.find_notification_items(hs.axuielement.applicationElement(app))
  local item = shell.pick_item_for_screen(items, screens.current():frame())
  if item == nil then
    hs.alert.show("Rakuen: Notification Center item not found in the menu bar")
    return
  end
  press_item(item)
end

local function capture_window()
  local win = hs.window.focusedWindow()
  if win == nil then
    hs.alert.show("Rakuen: no window to capture")
    return
  end

  local path = screenshot.file_path(os.getenv("HOME"), os.date("*t"))
  local executable, arguments = screenshot.window_command(win:id(), path)
  local task = hs.task.new(executable, function(exit_code)
    if exit_code == 0 then
      hs.alert.show("Screenshot saved to the Desktop")
    else
      hs.alert.show("Rakuen: screenshot failed. Allow Hammerspoon in Screen Recording")
    end
  end, arguments)
  task:start()
end

local function rule(description, from, to, action, feasibility, note)
  return {
    description = description,
    from = from,
    to = to,
    action = action,
    feasibility = feasibility,
    note = note,
  }
end

shell.rules = {
  rule(
    "Run dialog",
    "Cmd+Space",
    "Opt+F2",
    key_action({ "cmd" }, "space"),
    "yes",
    "Opens Spotlight. Cmd+Space stays Spotlight"
  ),
  rule(
    "Application grid",
    "Launchpad (F4)",
    "Cmd+A",
    deferred.guard(open_application_grid),
    "yes",
    "Opens Apps (Launchpad before macOS 26). Select All is Ctrl+A"
  ),
  rule(
    "Screenshot UI",
    "Cmd+Shift+5",
    "F13",
    key_action({ "cmd", "shift" }, "5"),
    "yes",
    "Mac keyboards have no Print key. F13 is the stand-in"
  ),
  rule(
    "Screenshot area",
    "Cmd+Shift+4",
    "Shift+F13",
    key_action({ "cmd", "shift" }, "4"),
    "yes",
    "Crosshair selection"
  ),
  rule(
    "Screenshot window",
    "Cmd+Shift+4 then Space",
    "Opt+F13",
    deferred.guard(capture_window),
    "yes",
    "screencapture -l. Needs Screen Recording permission. Saved to the Desktop"
  ),
  rule(
    "Screen recording UI",
    "Cmd+Shift+5",
    "Ctrl+Shift+Opt+R",
    key_action({ "cmd", "shift" }, "5"),
    "yes",
    "Opens the screenshot panel. The recording tab is not separately addressable"
  ),
  rule(
    "Quick settings",
    "none",
    "Cmd+S",
    deferred.guard(open_quick_settings),
    "partial",
    "Opens System Settings. Control Center cannot be toggled. Save is Ctrl+S"
  ),
  rule(
    "Message tray",
    "none",
    "Cmd+M",
    deferred.guard(toggle_message_tray),
    "partial",
    "Clicks the Notification Center status item. That target moves across macOS versions. "
      .. "GNOME also binds Super+V; only Cmd+M is used so one action has one shortcut. "
      .. "Minimize is Cmd+H"
  ),
  rule(
    "Help",
    "Cmd+Shift+/",
    "Cmd+F1",
    key_action({ "cmd", "shift" }, "/"),
    "partial",
    "Sends the front app Help shortcut"
  ),
}

return shell
