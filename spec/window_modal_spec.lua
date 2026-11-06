local window_modal = require("rakuen.core.window_modal")

describe("window_modal.step", function()
  local area = { x = 0, y = 25, w = 1440, h = 800 }
  local original = { x = 200, y = 100, w = 600, h = 400 }

  it("moves with the arrow keys in steps", function()
    local result = window_modal.step("move", original, original, "right", false, area)
    assert.equals("continue", result.status)
    assert.same({ x = 220, y = 100, w = 600, h = 400 }, result.frame)

    result = window_modal.step("move", original, original, "up", false, area)
    assert.same({ x = 200, y = 80, w = 600, h = 400 }, result.frame)
  end)

  it("uses bigger steps with Shift", function()
    local result = window_modal.step("move", original, original, "down", true, area)
    assert.same({ x = 200, y = 200, w = 600, h = 400 }, result.frame)
  end)

  it("resizes from the bottom-right", function()
    local result = window_modal.step("resize", original, original, "right", false, area)
    assert.same({ x = 200, y = 100, w = 620, h = 400 }, result.frame)

    result = window_modal.step("resize", original, original, "up", false, area)
    assert.same({ x = 200, y = 100, w = 600, h = 380 }, result.frame)
  end)

  it("does not shrink below the minimum size", function()
    local tiny = { x = 0, y = 25, w = 210, h = 130 }
    local result = window_modal.step("resize", tiny, tiny, "left", true, area)
    assert.equals(window_modal.MIN_SIZE.w, result.frame.w)
  end)

  it("keeps the window reachable while moving", function()
    local near_edge = { x = 1400, y = 100, w = 600, h = 400 }
    local result = window_modal.step("move", near_edge, near_edge, "right", true, area)
    assert.is_true(result.frame.x <= area.w - window_modal.VISIBLE_MARGIN)
  end)

  it("accepts with Return and keeps the current frame", function()
    local moved = { x = 300, y = 100, w = 600, h = 400 }
    local result = window_modal.step("move", moved, original, "return", false, area)
    assert.equals("accept", result.status)
    assert.same(moved, result.frame)
  end)

  it("cancels with Escape and goes back to the original frame", function()
    local moved = { x = 300, y = 100, w = 600, h = 400 }
    local result = window_modal.step("move", moved, original, "escape", false, area)
    assert.equals("cancel", result.status)
    assert.same(original, result.frame)
  end)

  it("ignores other keys", function()
    local result = window_modal.step("move", original, original, "a", false, area)
    assert.equals("continue", result.status)
    assert.equals(original, result.frame)
  end)

  it("rejects an unknown mode", function()
    assert.has_error(function()
      window_modal.step("spin", original, original, "left", false, area)
    end)
  end)
end)
