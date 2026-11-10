-- Pure frame math for the windows module.
--
-- A frame is a table { x, y, w, h }. Hammerspoon frames have the same fields,
-- so these functions work on both. Nothing here touches `hs`.

local frame_math = {}

-- Pixels two frames may differ and still count as the same frame. Apps round
-- sizes and positions, so exact equality is too strict.
frame_math.DEFAULT_TOLERANCE = 8

function frame_math.copy(frame)
  return { x = frame.x, y = frame.y, w = frame.w, h = frame.h }
end

function frame_math.same_frame(first, second, tolerance)
  local allowed = tolerance or frame_math.DEFAULT_TOLERANCE
  return math.abs(first.x - second.x) <= allowed
    and math.abs(first.y - second.y) <= allowed
    and math.abs(first.w - second.w) <= allowed
    and math.abs(first.h - second.h) <= allowed
end

--- The whole usable area. `area` is the screen frame without menu bar and Dock.
function frame_math.full(area)
  return frame_math.copy(area)
end

function frame_math.left_half(area)
  local width = math.floor(area.w / 2)
  return { x = area.x, y = area.y, w = width, h = area.h }
end

function frame_math.right_half(area)
  local left_width = math.floor(area.w / 2)
  return { x = area.x + left_width, y = area.y, w = area.w - left_width, h = area.h }
end

function frame_math.shift(frame, delta_x, delta_y)
  return { x = frame.x + delta_x, y = frame.y + delta_y, w = frame.w, h = frame.h }
end

--- Grow or shrink from the bottom-right corner, never below `min_size`.
function frame_math.resize(frame, delta_w, delta_h, min_size)
  return {
    x = frame.x,
    y = frame.y,
    w = math.max(min_size.w, frame.w + delta_w),
    h = math.max(min_size.h, frame.h + delta_h),
  }
end

--- Keep `margin` pixels of the frame inside `area` and the title bar reachable.
function frame_math.keep_visible(frame, area, margin)
  local min_x = area.x - frame.w + margin
  local max_x = area.x + area.w - margin
  local min_y = area.y
  local max_y = area.y + area.h - margin

  return {
    x = math.min(math.max(frame.x, min_x), max_x),
    y = math.min(math.max(frame.y, min_y), max_y),
    w = frame.w,
    h = frame.h,
  }
end

return frame_math
