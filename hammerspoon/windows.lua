local activeWindowsStore = {}

local eventsToMonitor = {
  hs.window.filter.windowFullscreened,
  hs.window.filter.windowMoved,
  hs.window.filter.windowCreated,
  hs.window.filter.windowDestroyed
}

-- Get focused window and screen
local function getFocusedWindow()
  local window = hs.window.focusedWindow()

  if not window then
    return nil
  end

  local screen = window:screen()
  local frame = screen:frame()

  return window, frame
end

-- Can parameters to have default values?
local function storeWindowFrame(focusedWin, windows, movingAction)
  local windowId = focusedWin and focusedWin:id()

  if not windowId then
    print("No window ID found in storeWindowFrame")

    return windows
  end

  local frame = focusedWin:frame()
  local windowStore = windows[windowId] or {}

  windowStore.frame = frame
  windowStore.movingAction = movingAction
  windows[windowId] = windowStore

  return windowStore
end

-- Move focused window to next screen
local function moveWindowToNextScreen()
  local window = hs.window.focusedWindow()

  if not window then
    return
  end

  local nextScreen = window:screen():next()
  window:moveToScreen(nextScreen)
end

-- Move focused window to previous screen
local function moveWindowToPreviousScreen()
  local window = hs.window.focusedWindow()

  if not window then
    return
  end

  local prevScreen = window:screen():previous()
  window:moveToScreen(prevScreen)
end

local function snappingWindows(window, direction)
  local windowId = window:id()
  local windowStore = activeWindowsStore[windowId]

  if not windowStore then
    windowStore = storeWindowFrame(window, activeWindowsStore)
  end

  windowStore.movingAction = "snapping:" .. direction

  activeWindowsStore[windowId] = windowStore
end

-- Snap active window to the left
local function snapLeft()
  local window, frame = getFocusedWindow()

  if not window then
    return
  end

  snappingWindows(window, "left")

  local screen = window:screen():frame()

  -- If already top or bottom half → convert to quarter (top-left or bottom-left)
  if frame.h <= screen.h * 0.51 and frame.y == screen.y then
    -- top-left
    window:setFrame({ x = screen.x, y = screen.y, w = screen.w / 2, h = screen.h / 2 })
  elseif frame.h <= screen.h * 0.51 and (frame.y + frame.h) >= (screen.y + screen.h - 2) then
    -- bottom-left
    window:setFrame({ x = screen.x, y = screen.y + screen.h / 2, w = screen.w / 2, h = screen.h / 2 })
  else
    -- normal left half
    window:setFrame({ x = screen.x, y = screen.y, w = screen.w / 2, h = screen.h })
  end
end

-- Snap active window to the right
local function snapRight()
  local window, frame = getFocusedWindow()

  if not window then
    return
  end

  snappingWindows(window, "right")

  local screen = window:screen():frame()

  -- If already top or bottom half → convert to quarter (top-right or bottom-right)
  if frame.h <= screen.h * 0.51 and frame.y == screen.y then
    window:setFrame({ x = screen.x + screen.w / 2, y = screen.y, w = screen.w / 2, h = screen.h / 2 })
  elseif frame.h <= screen.h * 0.51 and (frame.y + frame.h) >= (screen.y + screen.h - 2) then
    window:setFrame({ x = screen.x + screen.w / 2, y = screen.y + screen.h / 2, w = screen.w / 2, h = screen.h / 2 })
  else
    window:setFrame({ x = screen.x + screen.w / 2, y = screen.y, w = screen.w / 2, h = screen.h })
  end
end

-- Snap active window to the top
local function snapTop()
  local window, frame = getFocusedWindow()

  if not window then
    return
  end

  snappingWindows(window, "top")

  local screen = window:screen():frame()

  -- If already left or right half → convert to quarter (top-left or top-right)
  if frame.w <= screen.w * 0.51 and frame.x == screen.x then
    window:setFrame({ x = screen.x, y = screen.y, w = screen.w / 2, h = screen.h / 2 })
  elseif frame.w <= screen.w * 0.51 and (frame.x + frame.w) >= (screen.x + screen.w - 2) then
    window:setFrame({ x = screen.x + screen.w / 2, y = screen.y, w = screen.w / 2, h = screen.h / 2 })
  else
    window:setFrame({ x = screen.x, y = screen.y, w = screen.w, h = screen.h / 2 })
  end
end

-- Snap active window to the bottom
local function snapBottom()
  local window, frame = getFocusedWindow()

  if not window then
    return
  end

  snappingWindows(window, "bottom")

  local screen = window:screen():frame()

  -- If already left or right half → convert to quarter (bottom-left or bottom-right)
  if frame.w <= screen.w * 0.51 and frame.x == screen.x then
    window:setFrame({ x = screen.x, y = screen.y + screen.h / 2, w = screen.w / 2, h = screen.h / 2 })
  elseif frame.w <= screen.w * 0.51 and (frame.x + frame.w) >= (screen.x + screen.w - 2) then
    window:setFrame({ x = screen.x + screen.w / 2, y = screen.y + screen.h / 2, w = screen.w / 2, h = screen.h / 2 })
  else
    window:setFrame({ x = screen.x, y = screen.y + screen.h / 2, w = screen.w, h = screen.h / 2 })
  end
end

local function centerWindow()
  local window = getFocusedWindow()

  if not window then
    return
  end

  storeWindowFrame(window, activeWindowsStore, "centering")

  print("Centering window")
  window:centerOnScreen(window:screen(), true)
end

local function maximizeWindow()
  local window = getFocusedWindow()

  if not window then
    print("No window found in maximizeWindow")
    return
  end

  storeWindowFrame(window, activeWindowsStore, "maximizing")

  window:maximize(0)
end

local function restoreSnapped()
  local window, frame = getFocusedWindow()

  if not window then
    return
  end

  local windowId = window:id()
  local storedFrame = activeWindowsStore[windowId] and activeWindowsStore[windowId].frame

  if not windowId then
    print("No window ID found")
    return
  end

  if storedFrame then
    window:setFrame(storedFrame)

    print("Restored window to original size")
  else
    window:setFrame(frame)

    print("No stored frame found, keeping current frame")
  end
end

hs.window.filter.default:subscribe(eventsToMonitor, function(window, appName, event)
  print("Window event: " .. hs.inspect(event))

  if event == hs.window.filter.windowDestroyed then
    print("Window destroyed: " .. hs.inspect(window:id()))

    activeWindowsStore[window:id()] = nil

    return
  end

  if event == hs.window.filter.windowCreated then
    print("Window created: " .. hs.inspect(window:id()))

    storeWindowFrame(window, activeWindowsStore)

    return
  end

  if event == hs.window.filter.windowMoved then
    local windowId = window:id()
    local windowStore = activeWindowsStore[windowId]

    if (windowStore and windowStore.movingAction) then
      print("Window Store: " .. hs.inspect(windowStore))

      windowStore.movingAction = nil
      activeWindowsStore[windowId] = windowStore

      return
    end

    storeWindowFrame(window, activeWindowsStore)
  end
end)

local keybindings = {
  {
    action = "Snap window to top",
    from = { mods = { "cmd", "shift", "fn" }, key = "up" },
    to = {
      handler = snapTop
    },
  },
  {
    action = "Snap window to bottom",
    from = { mods = { "cmd", "shift", "fn" }, key = "down" },
    to = {
      handler = snapBottom
    },
  },
  {
    action = "Snap window to left",
    from = { mods = { "cmd", "shift", "fn" }, key = "left" },
    to = {
      handler = snapLeft
    },
  },
  {
    action = "Snap window to right",
    from = { mods = { "cmd", "shift", "fn" }, key = "right" },
    to = {
      handler = snapRight
    },
  },
  {
    action = "Center window",
    from = { mods = { "cmd", "shift" }, key = "c" },
    to = {
      handler = centerWindow
    },
  },
  {
    action = "Restore snapped window",
    from = { mods = { "cmd", "alt" }, key = "down" },
    to = {
      handler = restoreSnapped
    },
  },
  {
    action = "Maximize window",
    from = { mods = { "cmd", "alt" }, key = "up" },
    to = {
      handler = maximizeWindow
    },
  },
  {
    action = "Move window to next screen",
    from = { mods = { "cmd", "alt" }, key = "right" },
    to = {
      handler = moveWindowToNextScreen
    },
  },
  {
    action = "Move window to previous screen",
    from = { mods = { "cmd", "alt" }, key = "left" },
    to = {
      handler = moveWindowToPreviousScreen
    }
  }
}

return keybindings
