local logger = require('utils/logger')

local alpha = 0.7
local circle = nil
local color = "#6d6e6b"
local duration = 2
local isShowing = false
local modal = 0
local mouseTap = nil
local radius = 50
local timer = nil

---
--- Convert a hexadecimal color value to a color table compatible with hs.drawing.color.
---
--- @param hex string The hexadecimal color value. Can optionally start with a '#' character.
--- @param alpha number The alpha value of the color. Defaults to 1.
--- @return table color The color object.
local function hexadecimalToColor(hex, alpha)
  alpha = alpha or 1
  if hex:sub(1, 1) == '#' then
    hex = hex:sub(2)
  end

  if hex:len() == 3 then
    hex = hex:gsub('(.)', '%1%1')
  end

  local colorStruct = {
    red = tonumber(hex:sub(1, 2), 16) / 255,
    green = tonumber(hex:sub(3, 4), 16) / 255,
    blue = tonumber(hex:sub(5, 6), 16) / 255,
    alpha = alpha or 1
  }

  return colorStruct
end

local function startMouseFollower()
  if mouseTap then
    mouseTap:stop()
  end

  mouseTap = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function(event)
    if not circle then
      return false
    end

    local pos = hs.mouse.absolutePosition()
    local frame = hs.geometry.rect(pos.x - radius, pos.y - radius, radius * 2, radius * 2)
    circle:setFrame(frame)

    return false -- don't swallow the event
  end)

  mouseTap:start()
end

local function stopMouseFollower()
  if mouseTap then
    mouseTap:stop()
    mouseTap = nil
  end
end

local function show()
  if circle then
    circle:hide(0.5)

    if timer then
      timer:stop()
    end
  end

  local mousepoint = hs.mouse.absolutePosition()

  circle = hs.drawing.circle(
    hs.geometry.rect(
      mousepoint.x - radius,
      mousepoint.y - radius,
      radius * 2,
      radius * 2
    )
  )

  circle:setStrokeColor(hexadecimalToColor(color))
  circle:setFill(true)
  circle:setFillColor(hexadecimalToColor(color))
  circle:setAlpha(alpha)
  circle:setStrokeWidth(2)
  circle:bringToFront(true)
  circle:show(0.5)

  -- start following the mouse while visible
  startMouseFollower()

  timer = hs.timer.doAfter(duration, function()
    circle:hide(0.5)
    stopMouseFollower()

    hs.timer.doAfter(0.6, function()
      if circle then
        circle:delete()
        circle = nil
      end
    end)
  end)

  return circle
end

local keybindings = {
  {
    action = "Show Mouse Location",
    from = { mods = {}, key = "ctrl" },
    to = {
      handler = function()
        if not isShowing then
          modal = 0
          isShowing = true
          show()
        end
      end
    },
    condition = function()
      if (modal == 2) then
        return true
      end

      modal = modal + 1

      hs.timer.doAfter(1, function()
        isShowing = false
        modal = 0
      end)

      return false
    end,
  }
}

return keybindings
