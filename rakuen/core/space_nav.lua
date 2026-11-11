-- Pure helpers for the workspaces module: where to go among macOS Spaces.
--
-- Spaces form a horizontal list and do not wrap. Nothing here touches hs.*.

local space_nav = {}

local TARGETS = { previous = true, next = true, first = true, last = true }

--- Position of `wanted` in `ids`, or nil.
function space_nav.index_of(ids, wanted)
  for index, id in ipairs(ids) do
    if id == wanted then
      return index
    end
  end
  return nil
end

--- Return the id of the Space named by `which` ("previous", "next", "first"
--- or "last"), or nil when there is nothing to move to: the list is empty,
--- the current Space is unknown, or the current Space already is that one.
function space_nav.target_id(ids, current_id, which)
  assert(type(ids) == "table", "ids must be a table")
  assert(TARGETS[which], "unknown target: " .. tostring(which))

  local current_index = space_nav.index_of(ids, current_id)
  if current_index == nil then
    return nil
  end

  local target_index
  if which == "previous" then
    target_index = current_index - 1
  elseif which == "next" then
    target_index = current_index + 1
  elseif which == "first" then
    target_index = 1
  else
    target_index = #ids
  end

  if target_index < 1 or target_index > #ids or target_index == current_index then
    return nil
  end
  return ids[target_index]
end

--- Plan the key presses that reach a target Space.
--- Returns { direction = "left" | "right", count = n }, or nil when no move is needed.
function space_nav.plan(ids, current_id, which)
  local target = space_nav.target_id(ids, current_id, which)
  if target == nil then
    return nil
  end

  local distance = space_nav.index_of(ids, target) - space_nav.index_of(ids, current_id)
  if distance < 0 then
    return { direction = "left", count = -distance }
  end
  return { direction = "right", count = distance }
end

--- Direction to switch before removing the current Space, since macOS cannot
--- remove the Space being shown: left, or right when this is the first one.
--- Returns "left" | "right", or nil when the Space cannot go (the only Space,
--- or an unknown current Space).
function space_nav.removal_direction(ids, current_id)
  assert(type(ids) == "table", "ids must be a table")

  local current_index = space_nav.index_of(ids, current_id)
  if #ids < 2 or current_index == nil then
    return nil
  end
  if current_index == 1 then
    return "right"
  end
  return "left"
end

--- Text for the menu bar indicator: one glyph per Space, the current one
--- drawn with `active_glyph`.
function space_nav.indicator_text(ids, current_id, active_glyph, inactive_glyph)
  assert(type(ids) == "table", "ids must be a table")

  local glyphs = {}
  for _, id in ipairs(ids) do
    if id == current_id then
      table.insert(glyphs, active_glyph)
    else
      table.insert(glyphs, inactive_glyph)
    end
  end
  return table.concat(glyphs)
end

-- Size of the on-screen flash: one numbered square per Space.
local FLASH_BOX = 64
local FLASH_GAP = 12
local FLASH_PADDING = 24

--- Layout of the on-screen flash for `count` Spaces: the panel size and one
--- square per Space, relative to the panel's top-left corner.
--- Returns { width, height, boxes = { { x, y, w, h }, ... } }.
function space_nav.flash_layout(count)
  assert(type(count) == "number" and count >= 0, "count must be a number")

  local boxes = {}
  for index = 1, count do
    table.insert(boxes, {
      x = FLASH_PADDING + (index - 1) * (FLASH_BOX + FLASH_GAP),
      y = FLASH_PADDING,
      w = FLASH_BOX,
      h = FLASH_BOX,
    })
  end

  local content_width = 0
  if count > 0 then
    content_width = count * FLASH_BOX + (count - 1) * FLASH_GAP
  end
  return {
    width = content_width + 2 * FLASH_PADDING,
    height = FLASH_BOX + 2 * FLASH_PADDING,
    boxes = boxes,
  }
end

-- Where to grab a window: near its top-left corner, below the top edge.
local TITLE_BAR_OFFSET_X = 80
local TITLE_BAR_OFFSET_Y = 18

--- Pixels the drag moves; small enough for the frame restore to undo.
space_nav.DRAG_NUDGE = 1

--- Point in the top-left of the title bar, used to grab a window. Away from
--- the middle, which often holds tabs, a search field or toolbar buttons.
function space_nav.title_bar_point(frame)
  assert(type(frame) == "table", "frame must be a table")
  return {
    x = frame.x + math.min(TITLE_BAR_OFFSET_X, frame.w / 2),
    y = frame.y + math.min(TITLE_BAR_OFFSET_Y, frame.h / 2),
  }
end

--- A point a little away from `point`, to start a drag.
function space_nav.drag_point(point)
  return { x = point.x + space_nav.DRAG_NUDGE, y = point.y }
end

return space_nav
