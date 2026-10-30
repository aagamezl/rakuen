local rule = require("core.rule")

local everyone = { enable = {}, disable = {} }

local function wrap(index, count)
  return ((index - 1) % count) + 1
end

local function cycleList(items, focusedId, backward, idOf)
  if #items == 0 then
    return
  end

  idOf = idOf or function(item)
    return item:id()
  end

  local index = 1

  for i, item in ipairs(items) do
    if idOf(item) == focusedId then
      index = i
      break
    end
  end

  local step = backward and -1 or 1
  local nextItem = items[wrap(index + step, #items)]

  if nextItem then
    nextItem:focus()
  end
end

local function cycleAppWindows(backward)
  local app = hs.application.frontmostApplication()

  if not app then
    return
  end

  local focused = hs.window.focusedWindow()

  cycleList(app:visibleWindows(), focused and focused:id(), backward)
end

local function cycleSpaceWindows(backward)
  local focused = hs.window.focusedWindow()
  local windows = hs.window.filter.new():setCurrentSpace(true):getWindows()

  cycleList(windows, focused and focused:id(), backward)
end

local function visibleApps()
  local apps = {}

  for _, app in ipairs(hs.application.runningApplications()) do
    local ok, windows = pcall(function()
      return app:visibleWindows()
    end)

    if ok and windows and #windows > 0 then
      table.insert(apps, app)
    end
  end

  table.sort(apps, function(a, b)
    return (a:name() or "") < (b:name() or "")
  end)

  return apps
end

local function switchApplication(backward)
  local apps = visibleApps()
  local front = hs.application.frontmostApplication()

  cycleList(apps, front and front:pid(), backward, function(app)
    return app:pid()
  end)
end

return {
  name = "Focus",
  rules = {
    rule({
      description = "Switch applications",
      gnome = "Alt+Tab",
      original = "Cmd+Tab",
      mods = { "alt" },
      key = "tab",
      applications = everyone,
      action = function() switchApplication(false) end,
      note = "Cmd+Tab stays the system switcher. Rakuen cannot intercept it",
    }),
    rule({
      description = "Switch applications backward",
      gnome = "Shift+Alt+Tab",
      original = "Cmd+Shift+Tab",
      mods = { "alt", "shift" },
      key = "tab",
      applications = everyone,
      action = function() switchApplication(true) end,
      note = "Cmd+Shift+Tab stays the system switcher",
    }),
    rule({ description = "Cycle app windows", gnome = "Alt+grave", original = "Cmd+grave", mods = { "alt" }, key = "`", applications = everyone, action = function() cycleAppWindows(false) end }),
    rule({ description = "Cycle app windows", gnome = "Super+grave", original = "Cmd+grave", mods = { "cmd" }, key = "`", applications = everyone, action = function() cycleAppWindows(false) end }),
    rule({ description = "Cycle app windows backward", gnome = "Shift+Alt+grave", original = "Cmd+Shift+grave", mods = { "alt", "shift" }, key = "`", applications = everyone, action = function() cycleAppWindows(true) end }),
    rule({ description = "Cycle app windows backward", gnome = "Shift+Super+grave", original = "Cmd+Shift+grave", mods = { "cmd", "shift" }, key = "`", applications = everyone, action = function() cycleAppWindows(true) end }),
    rule({ description = "Cycle all windows", gnome = "Alt+Escape", original = "none", mods = { "alt" }, key = "escape", applications = everyone, action = function() cycleSpaceWindows(false) end, note = "Windows on the current Space" }),
    rule({ description = "Cycle all windows backward", gnome = "Shift+Alt+Escape", original = "none", mods = { "alt", "shift" }, key = "escape", applications = everyone, action = function() cycleSpaceWindows(true) end }),
    rule({ description = "Cycle group", gnome = "Alt+F6", original = "Cmd+grave", mods = { "alt" }, key = "f6", applications = everyone, action = function() cycleAppWindows(false) end }),
    rule({ description = "Cycle group backward", gnome = "Shift+Alt+F6", original = "Cmd+Shift+grave", mods = { "alt", "shift" }, key = "f6", applications = everyone, action = function() cycleAppWindows(true) end }),
  },
}
