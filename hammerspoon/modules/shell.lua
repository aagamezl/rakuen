local apps = require("config.apps")
local binder = require("core.binder")
local favorites = require("config.favorites")
local rule = require("core.rule")
local spaces = require("core.spaces")

local everyone = { enable = {}, disable = {} }
local numberApps = { enable = {}, disable = apps.numberApps }

local function openSpotlight()
  binder.fire({ "cmd" }, "space")
end

local function openLaunchpad()
  if not hs.application.launchOrFocus("Launchpad") then
    binder.fire({}, "f4")
  end
end

local function screenshotPanel()
  binder.fire({ "cmd", "shift" }, "5")
end

local function screenshotArea()
  binder.fire({ "cmd", "shift" }, "4")
end

local function screenshotWindow()
  local win = hs.window.focusedWindow()

  if not win then
    hs.alert.show("No focused window to capture")

    return
  end

  local desktop = os.getenv("HOME") .. "/Desktop"
  local path = desktop .. "/rakuen-window.png"

  hs.task.new("/usr/sbin/screencapture", nil, { "-l", tostring(win:id()), path }):start()
  hs.alert.show("Saved " .. path)
end

local function switchSpace(key)
  spaces.move(key, 1)
end

local function openSystemSettings()
  hs.task.new("/usr/bin/open", nil, { "-a", "System Settings" }):start()
end

local function clickStatusItem(processNames, itemNames)
  for _, processName in ipairs(processNames) do
    for _, itemName in ipairs(itemNames) do
      local script = string.format([[
        tell application "System Events"
          tell process "%s"
            click menu bar item "%s" of menu bar 1
          end tell
        end tell
      ]], processName, itemName)

      local ok, success = pcall(hs.osascript.applescript, script)

      if ok and success then
        return true
      end
    end
  end

  return false
end

local function messageTray()
  local opened = clickStatusItem(
    { "ControlCenter", "Control Center" },
    { "Notification Center", "Clock", "Control Center" }
  )

  if not opened then
    hs.alert.show("Could not open Notification Center")
  end
end

local function focusFavorite(index)
  local name = favorites[index]

  if not name or name == "" then
    hs.alert.show("No favorite app in slot " .. index)

    return
  end

  hs.application.launchOrFocus(name)
end

local function newWindowOfFavorite(index)
  local name = favorites[index]

  if not name or name == "" then
    hs.alert.show("No favorite app in slot " .. index)

    return
  end

  hs.application.launchOrFocus(name)
  hs.timer.doAfter(0.3, function()
    local app = hs.application.find(name)

    if not app then
      hs.alert.show("Could not find " .. name)

      return
    end

    local selected = app:selectMenuItem({ "File", "New Window" })

    if not selected then
      hs.alert.show(name .. " has no New Window menu item")
    end
  end)
end

local function helpMenu()
  binder.fire({ "cmd", "shift" }, "/")
end

local rules = {
  rule({ description = "Run dialog", gnome = "Alt+F2", original = "Cmd+Space", mods = { "alt" }, key = "f2", applications = everyone, action = openSpotlight, note = "Opens Spotlight. Cmd+Space stays Spotlight" }),
  rule({ description = "Application grid", gnome = "Super+A", original = "Launchpad (F4)", mods = { "cmd" }, key = "a", applications = everyone, action = openLaunchpad, note = "Select All is Ctrl+A" }),
  rule({ description = "Screenshot UI", gnome = "Print", original = "Cmd+Shift+5", mods = {}, key = "f13", applications = everyone, action = screenshotPanel, note = "F13 stands in for the Print key" }),
  rule({ description = "Screenshot UI", gnome = "Print", original = "Cmd+Shift+5", mods = { "cmd", "shift" }, key = "5", applications = everyone, action = "passthrough", note = "Native macOS shortcut" }),
  rule({ description = "Screenshot area", gnome = "Shift+Print", original = "Cmd+Shift+4", mods = { "shift" }, key = "f13", applications = everyone, action = screenshotArea }),
  rule({ description = "Screenshot window", gnome = "Alt+Print", original = "Cmd+Shift+4 then Space", mods = { "alt" }, key = "f13", applications = everyone, action = screenshotWindow, note = "Needs Screen Recording permission" }),
  rule({ description = "Screen recording UI", gnome = "Ctrl+Shift+Alt+R", original = "Cmd+Shift+5", mods = { "ctrl", "shift", "alt" }, key = "r", applications = everyone, action = screenshotPanel, note = "Opens the screenshot panel. The recording tab is not separately addressable" }),
  rule({ description = "Overview up", gnome = "Super+Alt+Up", original = "Ctrl+Left", mods = { "cmd", "alt" }, key = "up", applications = everyone, action = function() switchSpace("left") end, note = "macOS has no overview. Switches to the previous Space" }),
  rule({ description = "Overview down", gnome = "Super+Alt+Down", original = "Ctrl+Right", mods = { "cmd", "alt" }, key = "down", applications = everyone, action = function() switchSpace("right") end, note = "Switches to the next Space" }),
  rule({ description = "Quick settings", gnome = "Super+S", original = "none", mods = { "cmd" }, key = "s", applications = everyone, action = openSystemSettings, note = "Opens System Settings. Control Center cannot be toggled" }),
  rule({ description = "Message tray", gnome = "Super+V", original = "none", mods = { "cmd" }, key = "v", applications = everyone, action = messageTray, note = "The Notification Center status item moves across macOS versions" }),
  rule({ description = "Message tray", gnome = "Super+M", original = "none", mods = { "cmd" }, key = "m", applications = everyone, action = messageTray, note = "The Notification Center status item moves across macOS versions" }),
  rule({ description = "Help", gnome = "Super+F1", original = "Cmd+Shift+/", mods = { "cmd" }, key = "f1", applications = everyone, action = helpMenu, note = "Sends the front app Help shortcut" }),
}

for index = 1, 9 do
  local key = tostring(index)

  table.insert(rules, rule({
    description = "Favorite app " .. index,
    gnome = "Super+" .. index,
    original = "none",
    mods = { "cmd" },
    key = key,
    applications = numberApps,
    action = function() focusFavorite(index) end,
    note = "Disabled in apps that already use Command+number",
  }))

  table.insert(rules, rule({
    description = "New window of favorite app " .. index,
    gnome = "Super+Ctrl+" .. index,
    original = "none",
    mods = { "cmd", "ctrl" },
    key = key,
    applications = everyone,
    action = function() newWindowOfFavorite(index) end,
    note = "Uses the File > New Window menu item when the app has one",
  }))
end

return {
  name = "Shell",
  rules = rules,
}
