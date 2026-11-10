-- Tiling layouts and the arrow-key transitions between them (pure, no `hs`).
--
-- Layouts: full, left, right, top_left, top_right, bottom_left, bottom_right.
-- Pressing Cmd+<arrow> moves the window to the next layout, like the GNOME
-- Tiling Assistant: Left then Up gives the top-left quarter, Left then Down
-- the bottom-left quarter. Pressing the arrow that points at the edge the
-- window already sits on restores the window ("restore").

local frame_math = require("rakuen.core.frame_math")

local tiling = {}

tiling.RESTORE = "restore"

-- NEXT[current layout][direction] is the layout to go to, or "restore".
-- A missing current layout (a window that is not tiled) is stored under "none".
local NEXT = {
  none = { up = "full", down = "restore", left = "left", right = "right" },
  full = { up = "full", down = "restore", left = "left", right = "right" },
  left = { up = "top_left", down = "bottom_left", left = "restore", right = "right" },
  right = { up = "top_right", down = "bottom_right", left = "left", right = "restore" },
  top_left = { up = "full", down = "left", left = "restore", right = "top_right" },
  top_right = { up = "full", down = "right", left = "top_left", right = "restore" },
  bottom_left = { up = "left", down = "restore", left = "restore", right = "bottom_right" },
  bottom_right = { up = "right", down = "restore", left = "bottom_left", right = "restore" },
}

local LAYOUTS = {
  "full",
  "left",
  "right",
  "top_left",
  "top_right",
  "bottom_left",
  "bottom_right",
}

--- Frame of `layout` inside `area`.
function tiling.frame_for(layout, area)
  if layout == "full" then
    return frame_math.full(area)
  end
  if layout == "left" then
    return frame_math.left_half(area)
  end
  if layout == "right" then
    return frame_math.right_half(area)
  end
  if layout == "top_left" then
    return frame_math.quarter(area, "top", "left")
  end
  if layout == "top_right" then
    return frame_math.quarter(area, "top", "right")
  end
  if layout == "bottom_left" then
    return frame_math.quarter(area, "bottom", "left")
  end
  if layout == "bottom_right" then
    return frame_math.quarter(area, "bottom", "right")
  end
  error("unknown layout: " .. tostring(layout))
end

--- Name of the layout whose frame `frame` matches inside `area`, or nil.
function tiling.detect(frame, area)
  for _, layout in ipairs(LAYOUTS) do
    if frame_math.same_frame(frame, tiling.frame_for(layout, area)) then
      return layout
    end
  end
  return nil
end

--- The layout reached by pressing `direction` ("left", "right", "up", "down")
--- from `current` (a layout name or nil). Returns a layout name or "restore".
function tiling.next_layout(current, direction)
  local transitions = NEXT[current or "none"]
  assert(transitions ~= nil, "unknown layout: " .. tostring(current))

  local target = transitions[direction]
  assert(target ~= nil, "direction must be left, right, up or down")
  return target
end

return tiling
