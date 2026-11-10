-- Window actions: maximize, tile, move to display, close, minimize.
--
-- Works on any "window" object with the Hammerspoon window methods used below
-- (id, frame, setFrame, screen, isFullscreen, isStandard, close, minimize,
-- moveToScreen), so tests can pass fakes. The decisions come from
-- window_state and frame_math; this file only reads and writes windows.
--
-- Every action returns a status string:
--   "done"         the window changed
--   "unchanged"    nothing to do (already there, nothing to restore, no display that way)
--   "partial"      the app refused part of the new size
--   "unsupported"  fullscreen or non-standard window (dialogs, panels)

local frame_math = require("rakuen.core.frame_math")
local tiling = require("rakuen.core.tiling")
local window_state = require("rakuen.core.window_state")

local window_manager = {}
window_manager.__index = window_manager

-- Hammerspoon screen methods that return the neighbor display.
local NEIGHBOR_METHODS = {
  left = "toWest",
  right = "toEast",
  up = "toNorth",
  down = "toSouth",
}

-- Frames are set without animation so that reading the frame back is reliable.
local NO_ANIMATION = 0

function window_manager.new()
  return setmetatable({ states = {} }, window_manager)
end

local function is_manageable(win)
  return not win:isFullscreen() and win:isStandard()
end

local function usable_area(win)
  return win:screen():frame()
end

--- Move the window to `frame` and remember what is needed to restore it.
--- `original` is the frame to restore to; nil when restoring. `layout` is the
--- tiling layout name, kept so the next arrow press knows where the window is.
function window_manager:set_frame(win, frame, original, layout)
  win:setFrame(frame, NO_ANIMATION)
  local applied = win:frame()
  local window_id = win:id()

  if original == nil then
    self.states[window_id] = nil
    return "done"
  end

  self.states[window_id] =
    { original = original, requested = frame, applied = applied, layout = layout }

  if frame_math.same_frame(applied, frame, frame_math.DEFAULT_TOLERANCE) then
    return "done"
  end
  return "partial"
end

local function run_decision(self, win, decision)
  if decision.action == "none" then
    return "unchanged"
  end

  if decision.action == "restore" then
    return self:set_frame(win, decision.frame, nil)
  end

  return self:set_frame(win, decision.frame, decision.original, decision.layout)
end

--- Maximize, or restore when the window is already maximized by Rakuen.
function window_manager:toggle_maximize(win)
  return self:tile_to(win, "full")
end

--- Go back to the frame before Rakuen moved the window.
function window_manager:unmaximize(win)
  if not is_manageable(win) then
    return "unsupported"
  end

  local decision = window_state.decide_restore(win:frame(), self.states[win:id()])
  return run_decision(self, win, decision)
end

--- Go to `layout` ("left", "top_right", ...); press again to restore.
function window_manager:tile_to(win, layout)
  if not is_manageable(win) then
    return "unsupported"
  end

  local target = tiling.frame_for(layout, usable_area(win))
  local decision = window_state.decide_toggle(win:frame(), target, self.states[win:id()])
  decision.layout = layout
  return run_decision(self, win, decision)
end

--- Fill the left or right half; press again to restore.
function window_manager:tile(win, side)
  assert(side == "left" or side == "right", "side must be 'left' or 'right'")
  return self:tile_to(win, side)
end

--- The tiling layout the window is in, or nil for a free window. A layout Rakuen set
--- is trusted while the window has not moved, even when the app refused part of the size.
local function current_layout(win, area, state)
  local current = win:frame()
  if state ~= nil and state.layout ~= nil and frame_math.same_frame(current, state.applied) then
    return state.layout
  end
  return tiling.detect(current, area)
end

--- Cmd+<arrow>: move to the next tiling layout (halves, quarters, maximize).
function window_manager:tile_step(win, direction)
  if not is_manageable(win) then
    return "unsupported"
  end

  local area = usable_area(win)
  local current = win:frame()
  local state = self.states[win:id()]

  local layout = current_layout(win, area, state)
  local next_layout = tiling.next_layout(layout, direction)
  if next_layout == tiling.RESTORE then
    return run_decision(self, win, window_state.decide_restore(current, state))
  end

  local target = tiling.frame_for(next_layout, area)
  local decision = window_state.decide_apply(current, target, state)
  decision.layout = next_layout
  return run_decision(self, win, decision)
end

--- Send the window to the neighbor display. Does nothing when there is none.
--- A maximized or tiled window keeps its layout on the new display, and its
--- saved frame is scaled to that display so restoring still works.
function window_manager:move_to_display(win, direction)
  local method = NEIGHBOR_METHODS[direction]
  assert(method ~= nil, "direction must be left, right, up or down")

  if win:isFullscreen() then
    return "unsupported"
  end

  local current_screen = win:screen()
  local target_screen = current_screen[method](current_screen)
  if target_screen == nil then
    return "unchanged"
  end

  local source_area = usable_area(win)
  local state = self.states[win:id()]
  local layout = current_layout(win, source_area, state)

  win:moveToScreen(target_screen, false, true, NO_ANIMATION)
  self.states[win:id()] = nil

  if layout == nil then
    return "done"
  end

  local target_area = target_screen:frame()
  local original = win:frame()
  if state ~= nil then
    original = frame_math.rescale(state.original, source_area, target_area)
  end

  local target = tiling.frame_for(layout, target_area)
  return self:set_frame(win, target, original, layout)
end

function window_manager:close(win)
  win:close()
  self.states[win:id()] = nil
  return "done"
end

function window_manager.minimize(_, win)
  win:minimize()
  return "done"
end

return window_manager
