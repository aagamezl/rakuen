local frame_math = require("rakuen.core.frame_math")

describe("frame_math", function()
  local area = { x = 0, y = 25, w = 1440, h = 800 }

  it("treats frames within the tolerance as the same", function()
    local first = { x = 0, y = 25, w = 720, h = 800 }
    local second = { x = 3, y = 24, w = 722, h = 797 }
    assert.is_true(frame_math.same_frame(first, second))
  end)

  it("treats frames further apart than the tolerance as different", function()
    local first = { x = 0, y = 25, w = 720, h = 800 }
    local second = { x = 0, y = 25, w = 760, h = 800 }
    assert.is_false(frame_math.same_frame(first, second))
    assert.is_true(frame_math.same_frame(first, second, 50))
  end)

  it("splits the area into two halves that cover it", function()
    local left = frame_math.left_half(area)
    local right = frame_math.right_half(area)
    assert.same({ x = 0, y = 25, w = 720, h = 800 }, left)
    assert.same({ x = 720, y = 25, w = 720, h = 800 }, right)
  end)

  it("gives the odd pixel to the right half", function()
    local odd_area = { x = 100, y = 0, w = 1001, h = 500 }
    local left = frame_math.left_half(odd_area)
    local right = frame_math.right_half(odd_area)
    assert.equals(500, left.w)
    assert.equals(501, right.w)
    assert.equals(odd_area.x + odd_area.w, right.x + right.w)
  end)

  it("keeps the menu bar inset when filling the area", function()
    assert.same(area, frame_math.full(area))
  end)

  it("copies a frame without sharing the table", function()
    local original = { x = 1, y = 2, w = 3, h = 4 }
    local copy = frame_math.copy(original)
    copy.x = 99
    assert.equals(1, original.x)
  end)

  it("shifts a frame", function()
    assert.same(
      { x = 30, y = 15, w = 10, h = 10 },
      frame_math.shift({ x = 10, y = 20, w = 10, h = 10 }, 20, -5)
    )
  end)

  it("resizes from the bottom-right and respects the minimum size", function()
    local frame = { x = 10, y = 10, w = 300, h = 200 }
    local min_size = { w = 200, h = 120 }
    assert.same({ x = 10, y = 10, w = 320, h = 180 }, frame_math.resize(frame, 20, -20, min_size))
    assert.same(
      { x = 10, y = 10, w = 200, h = 120 },
      frame_math.resize(frame, -500, -500, min_size)
    )
  end)

  it("rescales a frame from one area to another", function()
    local big = { x = 1440, y = 25, w = 2880, h = 1600 }
    local result = frame_math.rescale({ x = 720, y = 425, w = 720, h = 400 }, area, big)
    assert.same({ x = 2880, y = 825, w = 1440, h = 800 }, result)
  end)

  it("keeps part of a moved window inside the area", function()
    local frame = { x = 5000, y = -300, w = 400, h = 300 }
    local kept = frame_math.keep_visible(frame, area, 80)
    assert.equals(area.x + area.w - 80, kept.x)
    assert.equals(area.y, kept.y)
    assert.equals(400, kept.w)
  end)

  it("lets a window sit partly off the left edge", function()
    local frame = { x = -300, y = 100, w = 400, h = 300 }
    local kept = frame_math.keep_visible(frame, area, 80)
    assert.equals(-300, kept.x)
    local far_left = frame_math.keep_visible({ x = -900, y = 100, w = 400, h = 300 }, area, 80)
    assert.equals(-320, far_left.x)
  end)
end)
