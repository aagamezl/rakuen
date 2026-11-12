-- Workspace indicator: one glyph per Space in the menu bar, plus a brief
-- on-screen flash when the Space changes (like the GNOME workspace popup).
--
-- Which glyphs to draw is decided by space_nav.indicator_text (pure). This
-- file only talks to Hammerspoon. The watchers and the menu bar item are
-- kept in module state so Lua does not garbage-collect them.

local screens = require("rakuen.core.screens")
local space_nav = require("rakuen.core.space_nav")

local space_indicator = {}

local MENU_ACTIVE = "□"
local MENU_INACTIVE = "▧"
local FLASH_SECONDS = 0.6
local FLASH_FADE_SECONDS = 0.15
local FLASH_RADIUS = 10
local FLASH_TEXT_SIZE = 36
-- Rough text height as a share of the text size, to center a number vertically.
local TEXT_HEIGHT_RATIO = 1.25

local BACKGROUND = { white = 0, alpha = 0.75 }
local LIGHT = { white = 1, alpha = 0.95 }
local DIM = { white = 1, alpha = 0.55 }
local DARK = { white = 0, alpha = 1 }

local state = {
  menubar = nil,
  flash = nil,
  space_watcher = nil,
  screen_watcher = nil,
}

--- Draw one square per Space, numbered from 1: the current one filled, the
--- others outlined. Replaces a flash that is still showing.
local function show_flash(screen, ids, current_id)
  if state.flash ~= nil then
    state.flash:delete()
    state.flash = nil
  end

  local layout = space_nav.flash_layout(#ids)
  local area = screen:frame()
  local canvas = hs.canvas.new({
    x = area.x + (area.w - layout.width) / 2,
    y = area.y + (area.h - layout.height) / 2,
    w = layout.width,
    h = layout.height,
  })

  canvas:level(hs.canvas.windowLevels.overlay)
  canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  canvas:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = BACKGROUND,
    roundedRectRadii = { xRadius = FLASH_RADIUS, yRadius = FLASH_RADIUS },
  })

  for index, box in ipairs(layout.boxes) do
    local is_current = ids[index] == current_id
    local frame = { x = box.x, y = box.y, w = box.w, h = box.h }

    if is_current then
      canvas:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = LIGHT,
        frame = frame,
      })
    else
      canvas:appendElements({
        type = "rectangle",
        action = "stroke",
        strokeColor = DIM,
        strokeWidth = 3,
        frame = frame,
      })
    end

    local text_height = FLASH_TEXT_SIZE * TEXT_HEIGHT_RATIO
    local text_color = LIGHT
    if is_current then
      text_color = DARK
    end

    canvas:appendElements({
      type = "text",
      text = tostring(index),
      textSize = FLASH_TEXT_SIZE,
      textColor = text_color,
      textAlignment = "center",
      frame = { x = box.x, y = box.y + (box.h - text_height) / 2, w = box.w, h = text_height },
    })
  end

  state.flash = canvas
  canvas:show(FLASH_FADE_SECONDS)

  hs.timer.doAfter(FLASH_SECONDS, function()
    if state.flash == canvas then
      canvas:delete(FLASH_FADE_SECONDS)
      state.flash = nil
    end
  end)
end

--- Redraw the menu bar title; flash the Spaces too when `flash` is true.
function space_indicator.render(flash)
  if state.menubar == nil then
    return
  end

  local screen = screens.current()
  local ids = hs.spaces.spacesForScreen(screen)
  local current_id = hs.spaces.activeSpaceOnScreen(screen)

  if ids == nil then
    return
  end

  state.menubar:setTitle(space_nav.indicator_text(ids, current_id, MENU_ACTIVE, MENU_INACTIVE))

  if flash then
    show_flash(screen, ids, current_id)
  end
end

--- Show the indicator and keep it current. Safe to call twice.
function space_indicator.start()
  if state.menubar ~= nil then
    return
  end

  state.menubar = hs.menubar.new()
  state.space_watcher = hs.spaces.watcher.new(function()
    space_indicator.render(true)
  end)
  state.screen_watcher = hs.screen.watcher.new(function()
    space_indicator.render(false)
  end)

  space_indicator.render(false)
  state.space_watcher:start()
  state.screen_watcher:start()
end

function space_indicator.stop()
  if state.menubar == nil then
    return
  end

  if state.flash ~= nil then
    state.flash:delete()
    state.flash = nil
  end

  state.space_watcher:stop()
  state.screen_watcher:stop()
  state.menubar:delete()
  state.menubar = nil
  state.space_watcher = nil
  state.screen_watcher = nil
end

return space_indicator
