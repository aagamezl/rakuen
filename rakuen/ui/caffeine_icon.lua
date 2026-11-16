-- Menu bar icons for the caffeine toggle: a coffee cup, drawn with hs.canvas.
--
-- Active is a filled cup with three steam wisps. Inactive is an empty outline.
-- Both are plain white images (not templates), so they stay white on any menu bar.

local caffeine_icon = {}

local SIZE = 18
local STROKE = 1.4

-- Shapes in an 18x18 box. Pure data, so the layout can be tested without hs.
caffeine_icon.CUP = { x = 3, y = 8, w = 9, h = 7, radius = 2 }
caffeine_icon.HANDLE = { x = 12, y = 9.5, w = 3.5, h = 3.5 }
caffeine_icon.SAUCER = { x1 = 2, x2 = 14, y = 16.5 }
caffeine_icon.STEAM_X = { 5.5, 7.5, 9.5 }
caffeine_icon.STEAM_TOP = 2.5
caffeine_icon.STEAM_BOTTOM = 6

-- White shows on a dark menu bar. On a light one it would be hard to see.
local WHITE = { white = 1, alpha = 1 }

local function cup_element(active)
  local cup = caffeine_icon.CUP
  local action = "stroke"
  if active then
    action = "strokeAndFill"
  end

  return {
    type = "rectangle",
    frame = { x = cup.x, y = cup.y, w = cup.w, h = cup.h },
    roundedRectRadii = { xRadius = cup.radius, yRadius = cup.radius },
    action = action,
    strokeColor = WHITE,
    fillColor = WHITE,
    strokeWidth = STROKE,
  }
end

local function handle_element()
  local handle = caffeine_icon.HANDLE

  return {
    type = "oval",
    frame = { x = handle.x, y = handle.y, w = handle.w, h = handle.h },
    action = "stroke",
    strokeColor = WHITE,
    strokeWidth = STROKE,
  }
end

local function line_element(from, to)
  return {
    type = "segments",
    coordinates = { from, to },
    action = "stroke",
    strokeColor = WHITE,
    strokeWidth = STROKE,
    strokeCapStyle = "round",
  }
end

local function saucer_element()
  local saucer = caffeine_icon.SAUCER

  return line_element({ x = saucer.x1, y = saucer.y }, { x = saucer.x2, y = saucer.y })
end

--- Canvas elements for the icon. Steam is drawn only when `active`.
function caffeine_icon.elements(active)
  local elements = { cup_element(active), handle_element(), saucer_element() }

  if active then
    for _, x in ipairs(caffeine_icon.STEAM_X) do
      table.insert(
        elements,
        line_element(
          { x = x, y = caffeine_icon.STEAM_BOTTOM },
          { x = x, y = caffeine_icon.STEAM_TOP }
        )
      )
    end
  end

  return elements
end

--- Build a template hs.image for the state, or nil when drawing fails.
function caffeine_icon.image(active)
  local succeeded, image = pcall(function()
    local canvas = hs.canvas.new({ x = 0, y = 0, w = SIZE, h = SIZE })
    canvas:appendElements(table.unpack(caffeine_icon.elements(active)))
    local rendered = canvas:imageFromCanvas()
    canvas:delete()
    return rendered:template(false)
  end)

  if not succeeded then
    return nil
  end

  return image
end

return caffeine_icon
