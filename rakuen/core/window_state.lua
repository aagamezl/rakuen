-- Decides what a window action does, given the window's saved state.
--
-- State per window: { original, requested, applied }
--   original   the frame before Rakuen first moved the window (what "restore" returns to)
--   requested  the frame Rakuen asked for last (maximize, left half, ...)
--   applied    the frame the window really has after that request (apps may refuse)
--
-- A state is stale when the window no longer sits at `applied`, for example
-- because the user dragged it. A stale state is ignored, so "restore" never
-- jumps back to an old position. Pure functions, no `hs`.

local frame_math = require("rakuen.core.frame_math")

local window_state = {}

--- Return the state when it still describes the window, otherwise nil.
local function live_state(current, state)
  if state == nil then
    return nil
  end

  if frame_math.same_frame(current, state.applied) then
    return state
  end

  return nil
end

local function at_target(current, target, live)
  if frame_math.same_frame(current, target) then
    return true
  end

  return live ~= nil and frame_math.same_frame(live.requested, target)
end

local function apply_decision(current, target, live)
  local original = current
  if live ~= nil then
    original = live.original
  end
  return { action = "apply", frame = target, original = original }
end

--- Press once to reach `target`, press again to go back (maximize toggle, tiling).
--- Returns { action = "apply", frame, original }, { action = "restore", frame }
--- or { action = "none" }.
function window_state.decide_toggle(current, target, state)
  local live = live_state(current, state)

  if at_target(current, target, live) then
    if live ~= nil then
      return { action = "restore", frame = live.original }
    end
    return { action = "none" }
  end

  return apply_decision(current, target, live)
end

--- Go to `target`; do nothing when the window is already there.
function window_state.decide_apply(current, target, state)
  local live = live_state(current, state)

  if at_target(current, target, live) then
    return { action = "none" }
  end

  return apply_decision(current, target, live)
end

--- Go back to the frame before Rakuen moved the window, if that is still known.
function window_state.decide_restore(current, state)
  local live = live_state(current, state)

  if live == nil then
    return { action = "none" }
  end

  return { action = "restore", frame = live.original }
end

return window_state
