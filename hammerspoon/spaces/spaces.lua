local eventtap = hs.eventtap
local mouse = hs.mouse
local window = hs.window
local timer = hs.timer
local geometry = hs.geometry
local spaces = hs.spaces
local ax = hs.axuielement

local logger = require('utils/logger')
local spaceIndicator = require('spaces/space-indicator')
local utils = require('utils/general')

-- local log = hs.logger.new('spaces', 'debug')
local HORIZONTAL_OFFSET = 30
local VERTICAL_OFFSET = 6
local DEFAULT_M_CWAIT_TIME = 0.3

-- hs.spaces.setDefaultMCwaitTime(DEFAULT_M_CWAIT_TIME)

-- local watcher = hs.spaces.watcher.new(function()
--   logger.info("Space changed", "spaces")
--   spaces.insertRemoveSpaceCallback()
-- end)

-- watcher:start()

spaceIndicator.init()

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

local function insertSpace()
  local currentScreen = hs.mouse.getCurrentScreen()
  local result, err = hs.spaces.addSpaceToScreen(currentScreen)

  if result then
    spaceIndicator.render()
  else
    logger.error("Failed to insert space: " .. err, "spaces")
  end
end

--- Move focused window to another space using real mouse events
--- @param direction string  -- "left", "right"
local function moveOneSpace(direction)
  local screenSpaces = hs.spaces.spacesForScreen(hs.mouse.getCurrentScreen())

  if #screenSpaces > 1 then
    hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()

    hs.eventtap.event.newKeyEvent(direction, true):post()
    hs.eventtap.event.newKeyEvent(direction, false):post()

    hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
  end
end

--- Move focused window to another space using real mouse events
--- @param direction string  -- "left", "right"
local function moveWindowToSpace(direction, debug)
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

--- Moves the focused window to the specified space.
--- @param spaceIndex number The index of the space to move the window to.
---                         Indexing starts from 1.
local function moveToSpace(spaceIndex)
  local currentScreen = hs.mouse.getCurrentScreen()

  local currentSpaceId = hs.spaces.activeSpaceOnScreen(currentScreen)
  local currentSpaceIndex = utils.findIndex(hs.spaces.spacesForScreen(currentScreen), currentSpaceId)

  for i = 1, math.abs(spaceIndex - currentSpaceIndex) do
    moveOneSpace(utils.ternary(spaceIndex > currentSpaceIndex, "right", "left"))
  end
end

local function removeSpace()
  local currentScreen = hs.mouse.getCurrentScreen()
  local screenSpaces = hs.spaces.spacesForScreen(currentScreen)

  if #screenSpaces > 1 then
    local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)

    moveOneSpace('left')

    hs.timer.doAfter(1.1, function()
      local result, message = pcall(hs.spaces.removeSpace, activeSpace)

      if result then
        spaceIndicator.render()
      else
        logger.error("Failed to remove space: " .. message, "spaces")
      end
    end)
  end
end

local keybindings = {
  {
    action = "Move to Space 1",
    from = { mods = { "ctrl", "cmd" }, key = "1" },
    to = {
      handler = function()
        moveToSpace(1)
      end
    },
  },
  {
    action = "Move to Space 2",
    from = { mods = { "ctrl", "cmd" }, key = "2" },
    to = {
      handler = function()
        moveToSpace(2)
      end
    },
  },
  {
    action = "Move to Space 3",
    from = { mods = { "ctrl", "cmd" }, key = "3" },
    to = {
      handler = function()
        moveToSpace(3)
      end
    },
  },
  {
    action = "Move to Space 4",
    from = { mods = { "ctrl", "cmd" }, key = "4" },
    to = {
      handler = function()
        moveToSpace(4)
      end
    },
  },
  {
    action = "Move to Space 5",
    from = { mods = { "ctrl", "cmd" }, key = "5" },
    to = {
      handler = function()
        moveToSpace(5)
      end
    },
  },
  {
    action = "Move to Space 6",
    from = { mods = { "ctrl", "cmd" }, key = "6" },
    to = {
      handler = function()
        moveToSpace(6)
      end
    },
  },
  {
    action = "Move to Space 7",
    from = { mods = { "ctrl", "cmd" }, key = "7" },
    to = {
      handler = function()
        moveToSpace(7)
      end
    },
  },
  {
    action = "Move to Space 8",
    from = { mods = { "ctrl", "cmd" }, key = "8" },
    to = {
      handler = function()
        moveToSpace(8)
      end
    },
  },
  {
    action = "Move to Space 9",
    from = { mods = { "ctrl", "cmd" }, key = "9" },
    to = {
      handler = function()
        moveToSpace(9)
      end
    },
  },
  {
    action = "Insert Space",
    from = { mods = { "cmd", "ctrl" }, key = "up" },
    to = {
      handler = function()
        logger.info("Inserting space", "spaces")

        insertSpace()
      end
    },
  },
  {
    action = "Delete Space",
    from = { mods = { "cmd", "ctrl" }, key = "down" },
    to = {
      handler = function()
        logger.info("Deleting space", "spaces")

        removeSpace()
      end
    },
  },
  {
    action = "Move window to Space Left",
    from = { mods = { "cmd", "ctrl", "alt" }, key = "left" },
    to = {
      handler = function()
        logger.log("Move window to Space Left", "spaces")

        moveWindowToSpace('left', true)
      end
    },
  },
  {
    action = "Move window to Space Right",
    from = { mods = { "cmd", "ctrl", "alt" }, key = "right" },
    to = {
      handler = function()
        logger.log("Move window to Space Right", "spaces")

        moveWindowToSpace('right', true)
      end
    },
  },
}

return keybindings
