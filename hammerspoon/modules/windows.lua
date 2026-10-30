local binder = require("core.binder")
local rule = require("core.rule")

local everyone = { enable = {}, disable = {} }
local savedFrames = {}
local tileSide = {}
local mode = nil
local modeOrigin = nil
local STEP = 24

local chooser = hs.chooser.new(function(choice)
  if choice and choice.fn then
    choice.fn()
  end
end)

local function focusedWindow()
  return hs.window.focusedWindow()
end

local function framesClose(a, b)
  if not a or not b then
    return false
  end

  return math.abs(a.x - b.x) < 8
    and math.abs(a.y - b.y) < 8
    and math.abs(a.w - b.w) < 8
    and math.abs(a.h - b.h) < 8
end

local function remember(win)
  local id = win:id()

  if id and not savedFrames[id] then
    savedFrames[id] = win:frame()
  end
end

local function restore(win)
  local id = win:id()
  local frame = id and savedFrames[id]

  if frame then
    win:setFrame(frame)
    savedFrames[id] = nil
    tileSide[id] = nil

    return true
  end

  return false
end

local function closeWindow()
  local win = focusedWindow()

  if win then
    win:close()
  end
end

local function minimizeWindow()
  local win = focusedWindow()

  if win then
    win:minimize()
  end
end

local function fillScreen(win)
  remember(win)
  win:maximize()
end

local function toggleMaximize()
  local win = focusedWindow()

  if not win then
    return
  end

  local full = win:screen():frame()

  if framesClose(win:frame(), full) then
    if not restore(win) then
      win:setFrame(full)
    end
  else
    fillScreen(win)
  end
end

local function maximizeWindow()
  local win = focusedWindow()

  if win then
    fillScreen(win)
  end
end

local function unmaximizeWindow()
  local win = focusedWindow()

  if win and not restore(win) then
    hs.alert.show("This window has no saved frame to restore")
  end
end

local function tile(side)
  local win = focusedWindow()

  if not win then
    return
  end

  local id = win:id()

  if tileSide[id] == side then
    restore(win)

    return
  end

  remember(win)

  local unit = side == "left"
    and { x = 0, y = 0, w = 0.5, h = 1 }
    or { x = 0.5, y = 0, w = 0.5, h = 1 }

  win:moveToUnit(unit)
  tileSide[id] = side
end

local SCREEN_METHODS = {
  left = "toWest",
  right = "toEast",
  up = "toNorth",
  down = "toSouth",
}

local function moveDisplay(direction)
  local win = focusedWindow()

  if not win then
    return
  end

  local screen = win:screen()
  local method = SCREEN_METHODS[direction]
  local target = screen[method](screen)

  if target and target ~= screen then
    win:moveToScreen(target)
  end
end

local function nudge(win, key)
  local frame = win:frame()

  if mode == "move" then
    if key == "left" then
      frame.x = frame.x - STEP
    elseif key == "right" then
      frame.x = frame.x + STEP
    elseif key == "up" then
      frame.y = frame.y - STEP
    elseif key == "down" then
      frame.y = frame.y + STEP
    else
      return false
    end
  elseif mode == "resize" then
    if key == "left" then
      frame.w = math.max(120, frame.w - STEP)
    elseif key == "right" then
      frame.w = frame.w + STEP
    elseif key == "up" then
      frame.h = math.max(80, frame.h - STEP)
    elseif key == "down" then
      frame.h = frame.h + STEP
    else
      return false
    end
  else
    return false
  end

  win:setFrame(frame)

  return true
end

local function handleMode(key)
  if not mode then
    return false
  end

  local win = focusedWindow()

  if not win then
    mode = nil

    return true
  end

  if key == "escape" then
    win:setFrame(modeOrigin)
    mode = nil
    hs.alert.show("Cancelled")

    return true
  end

  if key == "return" then
    mode = nil
    hs.alert.show("Done")

    return true
  end

  return nudge(win, key)
end

local function beginMode(kind)
  local win = focusedWindow()

  if not win then
    return
  end

  mode = kind
  modeOrigin = win:frame()
  hs.alert.show(kind == "move" and "Move: arrows, Return, Escape" or "Resize: arrows, Return, Escape")
end

local function showWindowMenu()
  chooser:choices({
    { text = "Close", subText = "Opt+F4", fn = closeWindow },
    { text = "Minimize", subText = "Cmd+H", fn = minimizeWindow },
    { text = "Maximize", subText = "Cmd+Up", fn = maximizeWindow },
    { text = "Unmaximize", subText = "Cmd+Down", fn = unmaximizeWindow },
    { text = "Tile left", subText = "Cmd+Left", fn = function() tile("left") end },
    { text = "Tile right", subText = "Cmd+Right", fn = function() tile("right") end },
    { text = "Move to display left", fn = function() moveDisplay("left") end },
    { text = "Move to display right", fn = function() moveDisplay("right") end },
    { text = "Move to display up", fn = function() moveDisplay("up") end },
    { text = "Move to display down", fn = function() moveDisplay("down") end },
  })
  chooser:placeholderText("Window actions")
  chooser:show()
end

binder.setInterceptor(handleMode)

return {
  name = "Windows",
  rules = {
    rule({ description = "Close", gnome = "Alt+F4", original = "Cmd+W", mods = { "alt" }, key = "f4", applications = everyone, action = closeWindow, note = "Apps that quit on the last window still quit" }),
    rule({ description = "Toggle maximize", gnome = "Alt+F10", original = "none", mods = { "alt" }, key = "f10", applications = everyone, action = toggleMaximize, note = "Fills the screen. Not a macOS fullscreen Space" }),
    rule({ description = "Maximize", gnome = "Super+Up", original = "none", mods = { "cmd" }, key = "up", applications = everyone, action = maximizeWindow, note = "Ignores the synthetic Cmd+Up sent by Ctrl+Home" }),
    rule({ description = "Unmaximize", gnome = "Super+Down", original = "none", mods = { "cmd" }, key = "down", applications = everyone, action = unmaximizeWindow, note = "Ignores the synthetic Cmd+Down sent by Ctrl+End" }),
    rule({ description = "Unmaximize", gnome = "Alt+F5", original = "none", mods = { "alt" }, key = "f5", applications = everyone, action = unmaximizeWindow }),
    rule({ description = "Tile left", gnome = "Super+Left", original = "none", mods = { "cmd" }, key = "left", applications = everyone, action = function() tile("left") end, note = "Press again to restore" }),
    rule({ description = "Tile right", gnome = "Super+Right", original = "none", mods = { "cmd" }, key = "right", applications = everyone, action = function() tile("right") end, note = "Press again to restore" }),
    rule({ description = "Minimize", gnome = "Super+H", original = "Cmd+M", mods = { "cmd" }, key = "h", applications = everyone, action = minimizeWindow, note = "Overrides Hide. Hide is Ctrl+H" }),
    rule({ description = "Move to display left", gnome = "Super+Shift+Left", original = "none", mods = { "cmd", "shift" }, key = "left", applications = everyone, action = function() moveDisplay("left") end }),
    rule({ description = "Move to display right", gnome = "Super+Shift+Right", original = "none", mods = { "cmd", "shift" }, key = "right", applications = everyone, action = function() moveDisplay("right") end }),
    rule({ description = "Move to display up", gnome = "Super+Shift+Up", original = "none", mods = { "cmd", "shift" }, key = "up", applications = everyone, action = function() moveDisplay("up") end, note = "No-op when displays are side by side" }),
    rule({ description = "Move to display down", gnome = "Super+Shift+Down", original = "none", mods = { "cmd", "shift" }, key = "down", applications = everyone, action = function() moveDisplay("down") end, note = "No-op when displays are side by side" }),
    rule({ description = "Begin move", gnome = "Alt+F7", original = "none", mods = { "alt" }, key = "f7", applications = everyone, action = function() beginMode("move") end, note = "Arrows move the window. Return ends, Escape cancels" }),
    rule({ description = "Begin resize", gnome = "Alt+F8", original = "none", mods = { "alt" }, key = "f8", applications = everyone, action = function() beginMode("resize") end, note = "Arrows resize from the bottom-right" }),
    rule({ description = "Window action menu", gnome = "Alt+Space", original = "none", mods = { "alt" }, key = "space", applications = everyone, action = showWindowMenu, note = "macOS has no GNOME window menu" }),
  },
}
