local frame_math = require("rakuen.core.frame_math")
local tiling = require("rakuen.core.tiling")

describe("tiling", function()
  local area = { x = 0, y = 25, w = 1440, h = 800 }
  local layouts = {
    "full",
    "left",
    "right",
    "top_left",
    "top_right",
    "bottom_left",
    "bottom_right",
  }

  it("builds the four quarters that cover the area", function()
    assert.same({ x = 0, y = 25, w = 720, h = 400 }, tiling.frame_for("top_left", area))
    assert.same({ x = 720, y = 25, w = 720, h = 400 }, tiling.frame_for("top_right", area))
    assert.same({ x = 0, y = 425, w = 720, h = 400 }, tiling.frame_for("bottom_left", area))
    assert.same({ x = 720, y = 425, w = 720, h = 400 }, tiling.frame_for("bottom_right", area))
  end)

  it("gives odd pixels to the right and bottom quarters", function()
    local odd = { x = 0, y = 0, w = 1001, h = 501 }
    local top_left = frame_math.quarter(odd, "top", "left")
    local bottom_right = frame_math.quarter(odd, "bottom", "right")
    assert.equals(500, top_left.w)
    assert.equals(250, top_left.h)
    assert.equals(odd.w, bottom_right.x + bottom_right.w)
    assert.equals(odd.h, bottom_right.y + bottom_right.h)
  end)

  it("detects each layout from its frame", function()
    for _, layout in ipairs(layouts) do
      assert.equals(layout, tiling.detect(tiling.frame_for(layout, area), area))
    end
  end)

  it("detects nothing for a free window", function()
    assert.is_nil(tiling.detect({ x = 300, y = 200, w = 500, h = 400 }, area))
  end)

  it("rejects an unknown layout", function()
    assert.has_error(function()
      tiling.frame_for("middle", area)
    end)
  end)

  it("has a transition for every layout and direction", function()
    for _, layout in ipairs(layouts) do
      for _, direction in ipairs({ "left", "right", "up", "down" }) do
        local target = tiling.next_layout(layout, direction)
        assert.is_string(target)
      end
    end
  end)

  it("only leads to known layouts or restore", function()
    local known = { restore = true }
    for _, layout in ipairs(layouts) do
      known[layout] = true
    end
    for _, layout in ipairs(layouts) do
      for _, direction in ipairs({ "left", "right", "up", "down" }) do
        assert.is_true(known[tiling.next_layout(layout, direction)], layout .. " " .. direction)
      end
    end
  end)

  it("starts a free window with halves or maximize", function()
    assert.equals("left", tiling.next_layout(nil, "left"))
    assert.equals("right", tiling.next_layout(nil, "right"))
    assert.equals("full", tiling.next_layout(nil, "up"))
    assert.equals("restore", tiling.next_layout(nil, "down"))
  end)

  it("reaches every quarter from a half with a vertical arrow", function()
    assert.equals("top_left", tiling.next_layout("left", "up"))
    assert.equals("bottom_left", tiling.next_layout("left", "down"))
    assert.equals("top_right", tiling.next_layout("right", "up"))
    assert.equals("bottom_right", tiling.next_layout("right", "down"))
  end)

  it("returns from a quarter to its half with the opposite vertical arrow", function()
    assert.equals("left", tiling.next_layout("top_left", "down"))
    assert.equals("left", tiling.next_layout("bottom_left", "up"))
    assert.equals("right", tiling.next_layout("top_right", "down"))
    assert.equals("right", tiling.next_layout("bottom_right", "up"))
  end)

  it("restores when the arrow points at the edge the window is on", function()
    assert.equals("restore", tiling.next_layout("left", "left"))
    assert.equals("restore", tiling.next_layout("top_right", "right"))
    assert.equals("restore", tiling.next_layout("full", "down"))
  end)

  it("rejects an unknown direction or layout", function()
    assert.has_error(function()
      tiling.next_layout("left", "sideways")
    end)
    assert.has_error(function()
      tiling.next_layout("middle", "left")
    end)
  end)
end)
