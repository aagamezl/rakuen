local mergeObjects = require('utils/mergeObjects')
local reloadConfig = require('utils/reloadConfig')

-- Window management
local windows = require('windows')

-- Keybindings Events management
local attachEvents = require('keybindings/utils/attachEvents')
local usage = require('keybindings/utils/usage')

-- Keybindings
local applicationManagement = require('keybindings/application-management')
local browserNavigation = require('keybindings/browser-navigation')
local editingText = require('keybindings/editing-text')
local generalSystem = require('keybindings/general-system')
local spaces = require("spaces/spaces")
local textCursorMovement = require('keybindings/text-cursor-movement')
local textSelection = require('keybindings/text-selection')

-- local dragWindowToSpace = require("spaces/spaces2")

-- Initialize Keybindings
local keybindings = mergeObjects(
  applicationManagement,
  browserNavigation,
  editingText,
  generalSystem,
  spaces,
  textCursorMovement,
  textSelection,
  windows
)

-- Initialize Keybindings
attachEvents(keybindings)

-- Initialize Usage
usage.init(keybindings)

-- Reload config on change
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

local win = hs.window.focusedWindow()

-- hs.spaces.gotoSpace(504)
-- local result = hs.spaces.moveWindowToSpace(win:id(), 504, true)
-- print("Result: " .. hs.inspect(result))

local cache = {}

-- local function moveToSpace(win, direction)
--   local clickPoint = win:zoomButtonRect()
--   local sleepTime = 1000
--   local targetSpace = 504

--   -- check if all conditions are ok to move the window
--   local shouldMoveWindow =
--       hs.fnutils.every(
--         {
--           clickPoint ~= nil,
--           targetSpace ~= nil,
--           -- not isSpaceFullscreenApp(targetSpace),
--           not cache.movingWindowToSpace
--         },
--         function(test)
--           return test
--         end
--       )

--   if not shouldMoveWindow then
--     return
--   end

--   cache.movingWindowToSpace = true

--   cache.mousePosition = cache.mousePosition or hs.mouse.getAbsolutePosition()

--   clickPoint.x = clickPoint.x + clickPoint.w + 5
--   clickPoint.y = clickPoint.y + clickPoint.h / 2

--   -- fix for Chrome UI
--   if win:application():title() == "Google Chrome" then
--     clickPoint.y = clickPoint.y - clickPoint.h
--   end

--   -- focus screen before switching window
--   -- focusScreen(win:screen())
--   hs.window.focusedWindow():focus()

--   hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, clickPoint):post()
--   hs.timer.usleep(sleepTime)

--   hs.eventtap.keyStroke({ "cmd", "ctrl" }, direction == "east" and "right" or "left")

--   hs.timer.waitUntil(
--     function()
--       return spaces.activeSpace() == targetSpace
--     end,
--     function()
-- ONE FUNCTION that actually works on Sonoma/Tahoe
-- function moveWindowToSpaceSimple(window, spaceId)
--   cache.mousePosition = cache.mousePosition or hs.mouse.absolutePosition()

--   print("Mouse position: " .. hs.inspect(cache.mousePosition))

--   -- Get titlebar region using zoom button rect as anchor
--   local zoomRect = win:zoomButtonRect()
--   if not zoomRect then
--     hs.alert.show("Cannot determine title bar position")
--     return false
--   end

--   local clickPoint = {
--     x = zoomRect.x + zoomRect.w + 5,
--     y = zoomRect.y + zoomRect.h / 2,
--   }

--   print("Click point: " .. hs.inspect(clickPoint))

--   -- Focus the window before starting the drag
--   win:focus()
--   hs.timer.usleep(100000)

--   -- Press and hold on the title bar
--   hs.timer.doAfter(0.1, function()
--     hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, clickPoint):post()
--   end)

--   hs.spaces.gotoSpace(spaceId)

--   hs.timer.doAfter(1, function()
--     spaces.moveWindowToSpace(win:id(), spaceId)
--   end)

--   -- local newClickPoint = {
--   --   x = zoomRect.x + 200 + zoomRect.w + 5,
--   --   y = zoomRect.y + 200 + zoomRect.h / 2,
--   -- }

--   -- print("Starting to release mouse")

--   -- hs.timer.doAfter(1, function()
--   --   print("Releasing mouse")
--   --   hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, newClickPoint):post()
--   --   hs.mouse.absolutePosition(cache.mousePosition)
--   -- end)
-- end

-- Example usage in your init.lua:
-- moveWindowToSpaceSimple(hs.window.focusedWindow(), 541) -- Move to space 2
-- dragWindowToSpace("left", true)

hs.alert.show("Config loaded")
