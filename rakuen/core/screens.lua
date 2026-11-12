-- Which display Rakuen acts on.

local screens = {}

--- The display under the mouse pointer: the one macOS switches Spaces on and
--- the one the user is looking at. Falls back to the focused window's display.
function screens.current()
  local screen = nil

  if hs.mouse ~= nil then
    screen = hs.mouse.getCurrentScreen()
  end

  return screen or hs.screen.mainScreen()
end

return screens
