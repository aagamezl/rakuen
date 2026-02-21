local logger = require("utils/logger")

local eventtap = hs.eventtap
local mouse = hs.mouse
local window = hs.window
local timer = hs.timer
local geometry = hs.geometry
local ax = hs.axuielement

local activeWindowsStore = {}
local HORIZONTAL_OFFSET = 30
local VERTICAL_OFFSET = 10

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

  -- logger.info("Centering window", "windows")

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

    -- logger.info("Restored window to original size", "windows")
  else
    window:setFrame(frame)

    -- logger.info("No stored frame found, keeping current frame", "windows")
  end
end

-- --- Find an AX child element by role
-- --- @param element hs.axuielement
-- --- @param role string
-- --- @return hs.axuielement|nil
-- local function findAXChildByRole(element, role)
--   local children = element.AXChildren
--   if not children then return nil end

--   for _, child in ipairs(children) do
--     if child.AXRole == role then
--       return child
--     end
--   end

--   return nil
-- end

--- Get the title bar point for a window
--- @param win hs.window
--- @param horizontalOffset number
--- @param verticalOffset number
--- @return hs.geometry.point
local function getTitleBarPoint(win, horizontalOffset, verticalOffset)
  local frame = win:frame()

  return geometry.point(frame.x + horizontalOffset, frame.y + verticalOffset)
end

--- Draw a debug point on screen
--- @param point hs.geometry.point
local function drawDebugPoint(point)
  local canvas = hs.canvas.new({
    x = point.x - 5,
    y = point.y - 5,
    w = 10,
    h = 10,
  })

  canvas[1] = {
    type = "circle",
    fillColor = { red = 1, green = 0, blue = 0, alpha = 0.8 },
  }

  canvas:show()

  logger.info("Showing debug point at: " .. point.x .. ", " .. point.y, "spaces")
  hs.timer.doAfter(1, function() canvas:delete() end)
end

--- Move focused window to another space using real mouse events
--- @param direction string  -- "left", "right"
--- @param debug boolean  -- whether to show debug information
local function moveWindowToSpace(direction, debug)
  local win = window.focusedWindow()
  if not win then return end

  local titleBarPoint = getTitleBarPoint(win, HORIZONTAL_OFFSET, VERTICAL_OFFSET)

  if debug then
    -- logger.info("titleBarPoint: " .. titleBarPoint.x .. ", " .. titleBarPoint.y, "windows")

    drawDebugPoint(titleBarPoint)
  end


  -- logger.info("win.width: " .. win:frame().w .. ", win.height: " .. win:frame().h, "windows")

  -- Save current mouse position
  local originalMousePos = mouse.absolutePosition()

  -- Move mouse to title bar
  mouse.absolutePosition(titleBarPoint)

  -- Mouse down
  eventtap.event.newMouseEvent(
    eventtap.event.types.leftMouseDown,
    titleBarPoint
  ):post()

  -- Small delay so macOS "grabs" the window
  timer.usleep(150000)

  -- Switch Space (must be enabled in System Settings)
  hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, true):post()
  hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()

  hs.eventtap.event.newKeyEvent(direction, true):post()
  hs.eventtap.event.newKeyEvent(direction, false):post()

  hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, false):post()
  hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()

  hs.timer.doAfter(0.2, function()
    -- Mouse up (release window)
    eventtap.event.newMouseEvent(
      eventtap.event.types.leftMouseUp,
      titleBarPoint
    ):post()

    -- Restore mouse positions
    mouse.absolutePosition(originalMousePos)

    hs.eventtap.event.newKeyEvent("escape", true):post()
    hs.eventtap.event.newKeyEvent("escape", false):post()
  end)
end

hs.window.filter.default:subscribe(eventsToMonitor, function(window, appName, event)
  -- logger.info("Window event: " .. hs.inspect(event), "windows")

  if event == hs.window.filter.windowDestroyed then
    -- logger.info("Window destroyed: " .. hs.inspect(window:id()), "windows")

    activeWindowsStore[window:id()] = nil

    return
  end

  if event == hs.window.filter.windowCreated then
    -- logger.info("Window created: " .. hs.inspect(window:id()), "windows")

    storeWindowFrame(window, activeWindowsStore)

    return
  end

  if event == hs.window.filter.windowMoved then
    local windowId = window:id()
    local windowStore = activeWindowsStore[windowId]

    if (windowStore and windowStore.movingAction) then
      -- logger.info("Window Store: " .. hs.inspect(windowStore), "windows")

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
      synthetic = true,
      to = {
        handler = snapTop
      },
    },
    {
      action = "Snap window to bottom",
      from = { mods = { "cmd" }, key = "down" },
      synthetic = true,
      to = {
        handler = snapBottom
      },
    },
    {
      action = "Snap window to left",
      from = { mods = { "cmd" }, key = "left" },
      synthetic = true,
      to = {
        handler = snapLeft
      },
    },
    {
      action = "Snap window to right",
      from = { mods = { "cmd" }, key = "right" },
      synthetic = true,
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
        {
      action = "Move window to Space Left",
      from = { mods = { "cmd", "alt" }, key = "pageup" },
      to = {
        handler = function()
          logger.log("Move window to Space Left", "spaces")

          moveWindowToSpace('left', false)
        end
      },
    },
    {
      action = "Move window to Space Right",
      from = { mods = { "cmd", "alt" }, key = "pagedown" },
      to = {
        handler = function()
          logger.log("Move window to Space Right", "spaces")

          moveWindowToSpace('right', false)
        end
      },
    }
  }
}

return keybindings
