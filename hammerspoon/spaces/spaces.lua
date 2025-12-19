local utils = require('utils/general')

local watcher = hs.spaces.watcher.new(function()
  print("Space changed")
  -- spaces.insertRemoveSpaceCallback()
end)

local function moveToSpace(fromIndex, toIndex)
  if fromIndex == toIndex then
    return
  end

  local direction = utils.ternary(toIndex < fromIndex, 'left', 'right')

  hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()

  print("Moving from space " .. fromIndex .. " to space " .. toIndex)

  for i = 1, math.abs(toIndex - fromIndex) do
    hs.eventtap.event.newKeyEvent(direction, true):post()
    hs.eventtap.event.newKeyEvent(direction, false):post()
  end

  hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
end

local function moveOneSpace(direction)
  local currentScreen = hs.mouse.getCurrentScreen()
  local screenSpaces = hs.spaces.spacesForScreen(currentScreen)

  print("Screen spaces: " .. hs.inspect(screenSpaces))
  print("direction: " .. direction)

  if #screenSpaces > 1 then
    local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)

    print("Active space: " .. hs.inspect(activeSpace))

    local index = utils.findIndex(screenSpaces, activeSpace)

    print("Index: " .. index)

    local nextIndex = utils.getNextIndex(index, #screenSpaces, direction)

    print("Moving from space " .. index .. " to space " .. nextIndex)

    moveToSpace(index, nextIndex)
    -- send escape to close Mission Control
    -- hs.spaces.gotoSpace(screenSpaces[nextIndex])
    -- hs.eventtap.event.newKeyEvent("escape", true):post()
    -- hs.eventtap.event.newKeyEvent("escape", false):post()
    -- -- hs.spaces.closeMissionControl()
  end
end

local function moveWindowOneSpace(direction)
  local currentWindow = hs.window.focusedWindow()

  if currentWindow == nil then
    print("No focused window found")
    return
  end

  local currentScreen = currentWindow:screen()
  local screenSpaces = hs.spaces.spacesForScreen(currentScreen)

  print("Current window: " .. hs.inspect(currentWindow:title()))
  print("Current screen: " .. hs.inspect(currentScreen:name()))
  print("Screen spaces: " .. hs.inspect(screenSpaces))

  if #screenSpaces > 1 then
    local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)
    local index = utils.findIndex(screenSpaces, activeSpace)
    local nextIndex = utils.getNextIndex(index, #screenSpaces, direction)

    print("Active space: " .. hs.inspect(activeSpace))
    print("Space index: " .. index)
    print("Next space index: " .. nextIndex)
    print("Target space: " .. hs.inspect(screenSpaces[nextIndex]))
    print("Direction: " .. direction)

    -- Try moving the window using the space ID directly
    local targetSpace = screenSpaces[nextIndex]
    local result = hs.spaces.moveWindowToSpace(currentWindow, targetSpace)

    print("Move window result: " .. hs.inspect(result))

    -- Verify the move by checking if the window is now on the target space
    hs.timer.doAfter(1, function()
      local windowSpaces = hs.spaces.windowsForSpace(targetSpace)
      local found = false
      for _, winId in ipairs(windowSpaces) do
        if winId == currentWindow:id() then
          found = true
          break
        end
      end
      print("Window successfully moved to target space: " .. tostring(found))
    end)
  else
    print("Only one space available on this screen")
  end
end

local function moveWindowToLeftSpace()
    moveWindowOneSpace('left')
end

local function moveWindowToRightSpace()
    moveWindowOneSpace('right')
end

function moveToScreen(direction)
    local cwin = hs.window.focusedWindow()
    if cwin then
        local cscreen = cwin:screen()
        if direction == "up" then
            cwin:moveOneScreenNorth()
        elseif direction == "down" then
            cwin:moveOneScreenSouth()
        elseif direction == "left" then
            cwin:moveOneScreenWest()
        elseif direction == "right" then
            cwin:moveOneScreenEast()
        elseif direction == "next" then
            cwin:moveToScreen(cscreen:next())
        else
            hs.alert.show("Unknown direction: " .. direction)
        end
    else
        hs.alert.show("No focused window!")
    end
end

local keybindings = {
  -- {
  --   action = "Move to Space 1",
  --   from = { mods = { "ctrl", "alt" }, key = "1" },
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
  {
    action = "Move to Space Left",
    from = { mods = { "ctrl", "alt" }, key = "left" },
    to = {
      handler = function()
        -- moveWindowOneSpace('left')
        moveOneSpace('left')
      end
    },
  },
  {
    action = "Move to Space Right",
    from = { mods = { "ctrl", "alt" }, key = "right" },
    to = {
      handler = function ()
        -- moveWindowOneSpace('right')
        moveOneSpace('right')
      end
    },
  },
  -- {
  --   action = "Move window to Space Left",
  --   from = { mods = { "ctrl", "alt", "shift" }, key = "left" },
  --   to = {
  --     handler = function()
  --       -- local currentScreen = hs.mouse.getCurrentScreen()
  --       -- local screenSpaces = hs.spaces.spacesForScreen(currentScreen)

  --       -- if #screenSpaces > 1 then
  --       --   local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)
  --       --   local index = utils.findIndex(screenSpaces, activeSpace)
  --       --   local nextIndex = utils.getNextIndex(index, #screenSpaces, 'left')
  --       --   local window = hs.window.focusedWindow()

  --       --   if window then
  --       --     hs.spaces.moveWindowToSpace(window, screenSpaces[nextIndex])
  --       --   end
  --       -- end
  --       -- moveOneSpace('left')
  --       hs.timer.doAfter(1, function()
  --         moveWindowToLeftSpace()
  --         hs.alert.show("Move window to Space Left")
  --       end)
  --       -- moveToScreen('left')
  --     end
  --   },
  -- },
  -- {
  --   action = "Move window to Space Right",
  --   from = { mods = { "ctrl", "alt", "shift" }, key = "right" },
  --   to = {
  --     handler = function()
  --       -- local currentScreen = hs.mouse.getCurrentScreen()
  --       -- local screenSpaces = hs.spaces.spacesForScreen(currentScreen)

  --       -- if #screenSpaces > 1 then
  --       --   local activeSpace = hs.spaces.activeSpaceOnScreen(currentScreen)
  --       --   local index = utils.findIndex(screenSpaces, activeSpace)
  --       --   local nextIndex = utils.getNextIndex(index, #screenSpaces, 'right')
  --       --   local window = hs.window.focusedWindow()

  --       --   if window then
  --       --     hs.spaces.moveWindowToSpace(window, screenSpaces[nextIndex])
  --       --   end
  --       -- end
  --       -- moveOneSpace('right')
  --       hs.timer.doAfter(1, function()
  --         moveWindowToRightSpace()
  --         hs.alert.show("Move window to Space Right")
  --       end)
  --       -- moveToScreen('right')
  --     end
  --   },
  -- },
}

watcher:start()

return keybindings
