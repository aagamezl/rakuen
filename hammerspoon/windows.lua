local logger = require("utils/logger")

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
    logger.error("No window ID found in storeWindowFrame", "windows")

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

local function snappingWindow(window, direction)
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

  snappingWindow(window, "left")

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

  snappingWindow(window, "right")

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

  snappingWindow(window, "top")

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

  snappingWindow(window, "bottom")

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

  snappingWindow(window, "centering")

  logger.info("Centering window", "windows")

  window:centerOnScreen(window:screen(), true)
end

local function maximizeWindow()
  local window = getFocusedWindow()

  if not window then
    logger.error("No window found in maximizeWindow", "windows")
    return
  end

  window:maximize(0)
end

local function restoreSnapped()
  local window, frame = getFocusedWindow()

  if not window then
    return
  end

  local windowId = window:id()

  if not windowId then
    logger.error("No window ID found", "windows")
    return
  end

  local storedFrame = activeWindowsStore[windowId] and activeWindowsStore[windowId].frame

  if storedFrame then
    window:setFrame(storedFrame)

    logger.info("Restored window to original size", "windows")
  else
    window:setFrame(frame)

    logger.info("No stored frame found, keeping current frame", "windows")
  end
end

hs.window.filter.default:subscribe(eventsToMonitor, function(window, appName, event)
  logger.info("Window event: " .. hs.inspect(event), "windows")

  if event == hs.window.filter.windowDestroyed then
    logger.info("Window destroyed: " .. hs.inspect(window:id()), "windows")

    activeWindowsStore[window:id()] = nil

    return
  end

  if event == hs.window.filter.windowCreated then
    logger.info("Window created: " .. hs.inspect(window:id()), "windows")

    storeWindowFrame(window, activeWindowsStore)

    return
  end

  if event == hs.window.filter.windowMoved then
    local windowId = window:id()
    local windowStore = activeWindowsStore[windowId]

    if (windowStore and windowStore.movingAction) then
      logger.info("Window Store: " .. hs.inspect(windowStore), "windows")

      windowStore.movingAction = nil
      activeWindowsStore[windowId] = windowStore

      return
    end

    storeWindowFrame(window, activeWindowsStore)
  end
end)

local keybindings = {
  name = "Windows Management",
  rules = {
    {
      action = "Snap window to top",
      from = { mods = { "cmd" }, key = "up" },
      to = {
        handler = snapTop
      },
    },
    {
      action = "Snap window to bottom",
      from = { mods = { "cmd" }, key = "down" },
      to = {
        handler = snapBottom
      },
    },
    {
      action = "Snap window to left",
      from = { mods = { "cmd" }, key = "left" },
      to = {
        handler = snapLeft
      },
    },
    {
      action = "Snap window to right",
      from = { mods = { "cmd" }, key = "right" },
      to = {
        handler = snapRight
      },
    },
    {
      action = "Center window",
      from = { mods = { "cmd", "alt" }, key = "c" },
      to = {
        handler = centerWindow
      },
    },
    {
      action = "Move window to previous screen",
      from = { mods = { "cmd", "alt" }, key = "left" },
      to = {
        handler = moveWindowToPreviousScreen
      }
    },
    {
      action = "Move window to next screen",
      from = { mods = { "cmd", "alt" }, key = "right" },
      to = {
        handler = moveWindowToNextScreen
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
  }
}

return keybindings
