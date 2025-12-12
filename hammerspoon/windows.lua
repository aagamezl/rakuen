-- Get focused window and screen
local function getFocusedWindow()
  local win = hs.window.focusedWindow()

  if not win then return nil end
  local screen = win:screen()
  local frame = screen:frame()

  return win, frame
end

-- Move focused window to next screen
local function moveWindowToNextScreen()
  local win = hs.window.focusedWindow()
  if not win then return end
  local nextScreen = win:screen():next()
  win:moveToScreen(nextScreen)
end

-- Move focused window to previous screen
local function moveWindowToPreviousScreen()
  local win = hs.window.focusedWindow()
  if not win then return end
  local prevScreen = win:screen():previous()
  win:moveToScreen(prevScreen)
end

-- Snap active window to the left
local function snapLeft()
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen():frame()
  local f = win:frame()

  -- If already top or bottom half → convert to quarter (top-left or bottom-left)
  if f.h <= screen.h * 0.51 and f.y == screen.y then
    -- top-left
    win:setFrame({ x = screen.x, y = screen.y, w = screen.w / 2, h = screen.h / 2 })
  elseif f.h <= screen.h * 0.51 and (f.y + f.h) >= (screen.y + screen.h - 2) then
    -- bottom-left
    win:setFrame({ x = screen.x, y = screen.y + screen.h / 2, w = screen.w / 2, h = screen.h / 2 })
  else
    -- normal left half
    win:setFrame({ x = screen.x, y = screen.y, w = screen.w / 2, h = screen.h })
  end
end

-- Snap active window to the right
local function snapRight()
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen():frame()
  local f = win:frame()

  -- If already top or bottom half → convert to quarter (top-right or bottom-right)
  if f.h <= screen.h * 0.51 and f.y == screen.y then
    win:setFrame({ x = screen.x + screen.w / 2, y = screen.y, w = screen.w / 2, h = screen.h / 2 })
  elseif f.h <= screen.h * 0.51 and (f.y + f.h) >= (screen.y + screen.h - 2) then
    win:setFrame({ x = screen.x + screen.w / 2, y = screen.y + screen.h / 2, w = screen.w / 2, h = screen.h / 2 })
  else
    win:setFrame({ x = screen.x + screen.w / 2, y = screen.y, w = screen.w / 2, h = screen.h })
  end
end

-- Snap active window to the top
local function snapTop()
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen():frame()
  local f = win:frame()

  -- If already left or right half → convert to quarter (top-left or top-right)
  if f.w <= screen.w * 0.51 and f.x == screen.x then
    win:setFrame({ x = screen.x, y = screen.y, w = screen.w / 2, h = screen.h / 2 })
  elseif f.w <= screen.w * 0.51 and (f.x + f.w) >= (screen.x + screen.w - 2) then
    win:setFrame({ x = screen.x + screen.w / 2, y = screen.y, w = screen.w / 2, h = screen.h / 2 })
  else
    win:setFrame({ x = screen.x, y = screen.y, w = screen.w, h = screen.h / 2 })
  end
end

-- Snap active window to the bottom
local function snapBottom()
  local win = hs.window.focusedWindow()
  if not win then return end
  local screen = win:screen():frame()
  local f = win:frame()

  -- If already left or right half → convert to quarter (bottom-left or bottom-right)
  if f.w <= screen.w * 0.51 and f.x == screen.x then
    win:setFrame({ x = screen.x, y = screen.y + screen.h / 2, w = screen.w / 2, h = screen.h / 2 })
  elseif f.w <= screen.w * 0.51 and (f.x + f.w) >= (screen.x + screen.w - 2) then
    win:setFrame({ x = screen.x + screen.w / 2, y = screen.y + screen.h / 2, w = screen.w / 2, h = screen.h / 2 })
  else
    win:setFrame({ x = screen.x, y = screen.y + screen.h / 2, w = screen.w, h = screen.h / 2 })
  end
end

-- Restore snapped window to original size
local function restoreSnapped()
  local win, frame = getFocusedWindow()

  if not win then
    return
  end

  win:setFrame(frame)
end

local module = {}

function module.init()
  hs.hotkey.bind({ "cmd", "ctrl", "alt" }, "up", snapTop)
  hs.hotkey.bind({ "cmd", "ctrl", "alt" }, "down", snapBottom)
  hs.hotkey.bind({ "cmd", "ctrl", "alt" }, "left", snapLeft)
  hs.hotkey.bind({ "cmd", "ctrl", "alt" }, "right", snapRight)
  hs.hotkey.bind({ "cmd", "shift" }, "down", restoreSnapped)

  -- Built-in Mac keyboard: Ctrl + Cmd + Left/Right
  hs.hotkey.bind({ "shift", "cmd" }, "right", moveWindowToNextScreen)
  hs.hotkey.bind({ "shift", "cmd" }, "left", moveWindowToPreviousScreen)
end

return module