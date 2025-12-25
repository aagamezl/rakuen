local eventtap = hs.eventtap
local mouse = hs.mouse
local window = hs.window
local timer = hs.timer
local geometry = hs.geometry
local spaces = hs.spaces
local ax = hs.axuielement
local logger = require('utils/logger')

-- logger.isEnabled = false

local utils = require('utils/general')

-- local log = hs.logger.new('spaces', 'debug')
local HORIZONTAL_OFFSET = 30
local VERTICAL_OFFSET = 6
local DEFAULT_M_CWAIT_TIME = 0.3

hs.spaces.setDefaultMCwaitTime(DEFAULT_M_CWAIT_TIME)

local function findAXChildByRole(element, role)
  local children = element.AXChildren
  if not children then return nil end

  for _, child in ipairs(children) do
    if child.AXRole == role then
      return child
    end
  end

  return nil
end

local function getTitleBarPoint(win)
  local app = win:application()
  if not app then return nil end

  local axApp = ax.applicationElement(app)

  if not axApp then
    logger.warning("DEBUG: axApp is nil for app: " .. tostring(app:name()), "spaces")

    return nil
  end

  local axWindows = axApp.AXWindows
  if not axWindows then
    logger.warning("DEBUG: axWindows is nil for app: " .. tostring(app:name()), "spaces")

    return nil
  end

  local targetWindowNumber = win:id()

  for _, axWin in ipairs(axWindows) do
    -- Match by window number if available
    if axWin.AXWindowNumber == targetWindowNumber then
      local titleBar = findAXChildByRole(axWin, "AXTitleBar")

      if not titleBar or not titleBar.AXFrame then
        return nil
      end

      local f = titleBar.AXFrame
      -- return geometry.point(
      --   f.x + f.w / 2,
      --   f.y + f.h / 2
      -- )
      return geometry.point(
        f.x + HORIZONTAL_OFFSET,
        f.y + VERTICAL_OFFSET
      )
    end
  end

  return nil
end

-- local function screenForSpace(spaceID)
--   for _, screen in ipairs(hs.screen.allScreens()) do
--     local ids = spaces.spacesForScreen(screen)
--     for _, id in ipairs(ids or {}) do
--       if id == spaceID then
--         return screen
--       end
--     end
--   end
--   return nil
-- end

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

--- Drag focused window to another space using real mouse events
--- @param direction string  -- "left", "right"
local function dragWindowToSpace(direction, debug)
  local win = window.focusedWindow()
  if not win then return end

  local titleBarPoint = getTitleBarPoint(win)

  if not titleBarPoint then
    -- Fallback guess (last resort)
    logger.warning("Using fallback point", "spaces")

    local frame = win:frame()

    titleBarPoint = geometry.point(frame.x + HORIZONTAL_OFFSET, frame.y + VERTICAL_OFFSET)
  end

  if debug then
    logger.info("titleBarPoint: " .. titleBarPoint.x .. ", " .. titleBarPoint.y, "spaces")

    drawDebugPoint(titleBarPoint)
  end

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
  -- local direction = spaceID < spaces.space() and 'left' or 'right'
  hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()

  hs.eventtap.event.newKeyEvent(direction, true):post()
  hs.eventtap.event.newKeyEvent(direction, false):post()

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



local watcher = hs.spaces.watcher.new(function()
  logger.info("Space changed", "spaces")
  -- spaces.insertRemoveSpaceCallback()
end)

-- local function moveToSpace(fromIndex, toIndex)
--   if fromIndex == toIndex then
--     return
--   end

--   local direction = utils.ternary(toIndex < fromIndex, 'left', 'right')

--   hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()

--   print("Moving from space " .. fromIndex .. " to space " .. toIndex)

--   -- hs.spaces.gotoSpace(toIndex)
--   for i = 1, math.abs(toIndex - fromIndex) do
--     hs.eventtap.event.newKeyEvent(direction, true):post()
--     hs.eventtap.event.newKeyEvent(direction, false):post()
--   end

--   hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
-- end

-- local function moveOneSpace(direction)
--   local currentScreen = hs.mouse.getCurrentScreen()
--   local screenSpaces = hs.spaces.spacesForScreen(currentScreen)

--   print("Screen spaces: " .. hs.inspect(screenSpaces))
--   print("direction: " .. direction)

--   if #screenSpaces > 1 then
--     local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)

--     print("Active space: " .. hs.inspect(activeSpace))

--     local index = utils.findIndex(screenSpaces, activeSpace)

--     print("Index: " .. index)

--     local nextIndex = utils.getNextIndex(index, #screenSpaces, direction)

--     print("Moving from space " .. index .. " to space " .. nextIndex)

--     moveToSpace(index, nextIndex)
--     -- hs.spaces.gotoSpace(screenSpaces[nextIndex])

--     -- send escape to close Mission Control
--     -- hs.spaces.gotoSpace(screenSpaces[nextIndex])
--     -- hs.eventtap.event.newKeyEvent("escape", true):post()
--     -- hs.eventtap.event.newKeyEvent("escape", false):post()
--     -- -- hs.spaces.closeMissionControl()
--   end
-- end

-- local function moveWindowOneSpace(direction)
--   local currentWindow = hs.window.focusedWindow()

--   if currentWindow == nil then
--     print("No focused window found")
--     return
--   end

--   local currentScreen = currentWindow:screen()
--   local screenSpaces = hs.spaces.spacesForScreen(currentScreen)

--   print("Current window: " .. hs.inspect(currentWindow:title()))
--   print("Current screen: " .. hs.inspect(currentScreen:name()))
--   print("Screen spaces: " .. hs.inspect(screenSpaces))

--   if #screenSpaces > 1 then
--     local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)
--     local index = utils.findIndex(screenSpaces, activeSpace)
--     local nextIndex = utils.getNextIndex(index, #screenSpaces, direction)

--     print("Active space: " .. hs.inspect(activeSpace))
--     print("Space index: " .. index)
--     print("Next space index: " .. nextIndex)
--     print("Target space: " .. hs.inspect(screenSpaces[nextIndex]))
--     print("Direction: " .. direction)

--     -- Try moving the window using the space ID directly
--     local targetSpace = screenSpaces[nextIndex]
--     local result = hs.spaces.moveWindowToSpace(currentWindow, targetSpace)

--     print("Move window result: " .. hs.inspect(result))

--     -- Verify the move by checking if the window is now on the target space
--     hs.timer.doAfter(1, function()
--       local windowSpaces = hs.spaces.windowsForSpace(targetSpace)
--       local found = false
--       for _, winId in ipairs(windowSpaces) do
--         if winId == currentWindow:id() then
--           found = true
--           break
--         end
--       end
--       print("Window successfully moved to target space: " .. tostring(found))
--     end)
--   else
--     print("Only one space available on this screen")
--   end
-- end

-- local function moveWindowToLeftSpace()
--     moveWindowOneSpace('left')
-- end

-- local function moveWindowToRightSpace()
--     moveWindowOneSpace('right')
-- end

-- local function moveToScreen(direction)
--     local cwin = hs.window.focusedWindow()
--     if cwin then
--         local cscreen = cwin:screen()
--         if direction == "up" then
--             cwin:moveOneScreenNorth()
--         elseif direction == "down" then
--             cwin:moveOneScreenSouth()
--         elseif direction == "left" then
--             cwin:moveOneScreenWest()
--         elseif direction == "right" then
--             cwin:moveOneScreenEast()
--         elseif direction == "next" then
--             cwin:moveToScreen(cscreen:next())
--         else
--             hs.alert.show("Unknown direction: " .. direction)
--         end
--     else
--         hs.alert.show("No focused window!")
--     end
-- end

local keybindings = {
  -- {
  --   action = "Move to Space 1",
  --   from = { mods = { "ctrl", "alt"}, key = "1" },
  --   to = {
  --     handler = function()
  --       moveOneSpace('left')
  --     end
  --   },
  -- },
  -- {
  --   action = "Move to Space 2",
  --   from = { mods = { "ctrl", "alt" }, key = "2" },
  --   to = {
  --     handler = function()
  --       moveOneSpace('right')
  --     end
  --   },
  -- },
  -- {
  --   action = "Move to Space 3",
  --   from = { mods = { "ctrl", "alt" }, key = "3" },
  --   to = {
  --     handler = function()
  --       moveOneSpace('left')
  --     end
  --   },
  -- },
  -- {
  --   action = "Move to Space Left",
  --   from = { mods = { "cmd", "ctrl" }, key = "left" },
  --   to = {
  --     handler = function()
  --       moveOneSpace('left')
  --     end
  --   },
  -- },
  -- {
  --   action = "Move to Space Right",
  --   from = { mods = { "cmd", "ctrl" }, key = "right" },
  --   to = {
  --     handler = function ()
  --       moveOneSpace('right')
  --     end
  --   },
  -- },
  {
    action = "Move window to Space Left",
    from = { mods = { "cmd", "ctrl", "alt" }, key = "left" },
    to = {
      handler = function()
        logger.log("Move window to Space Left", "spaces")

        dragWindowToSpace('left', true)
      end
    },
  },
  {
    action = "Move window to Space Right",
    from = { mods = { "cmd", "ctrl", "alt" }, key = "right" },
    to = {
      handler = function()
        logger.log("Move window to Space Right", "spaces")

        dragWindowToSpace('right', true)
      end
    },
  },
}

watcher:start()

return keybindings
