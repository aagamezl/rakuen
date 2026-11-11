local space_nav = require("rakuen.core.space_nav")

local IDS = { 10, 20, 30, 40 }

describe("space_nav.target_id", function()
  it("finds the previous and next Space", function()
    assert.equals(10, space_nav.target_id(IDS, 20, "previous"))
    assert.equals(30, space_nav.target_id(IDS, 20, "next"))
  end)

  it("does not wrap at the ends", function()
    assert.is_nil(space_nav.target_id(IDS, 10, "previous"))
    assert.is_nil(space_nav.target_id(IDS, 40, "next"))
  end)

  it("finds the first and last Space, or nil when already there", function()
    assert.equals(10, space_nav.target_id(IDS, 30, "first"))
    assert.equals(40, space_nav.target_id(IDS, 30, "last"))
    assert.is_nil(space_nav.target_id(IDS, 10, "first"))
    assert.is_nil(space_nav.target_id(IDS, 40, "last"))
  end)

  it("returns nil for an unknown current Space or an empty list", function()
    assert.is_nil(space_nav.target_id(IDS, 99, "next"))
    assert.is_nil(space_nav.target_id({}, 1, "next"))
  end)

  it("rejects an unknown target", function()
    assert.has_error(function()
      space_nav.target_id(IDS, 10, "up")
    end)
  end)
end)

describe("space_nav.plan", function()
  it("counts the presses to the first and last Space", function()
    assert.same({ direction = "left", count = 2 }, space_nav.plan(IDS, 30, "first"))
    assert.same({ direction = "right", count = 3 }, space_nav.plan(IDS, 10, "last"))
  end)

  it("plans one press for previous and next", function()
    assert.same({ direction = "left", count = 1 }, space_nav.plan(IDS, 20, "previous"))
    assert.same({ direction = "right", count = 1 }, space_nav.plan(IDS, 20, "next"))
  end)

  it("returns nil when no move is needed", function()
    assert.is_nil(space_nav.plan(IDS, 10, "first"))
  end)
end)

describe("space_nav title bar points", function()
  it("grabs the title bar near the top-left corner", function()
    local point = space_nav.title_bar_point({ x = 100, y = 50, w = 400, h = 300 })
    assert.equals(68, point.y)
    assert.is_true(point.x > 100 and point.x <= 300)
  end)

  it("stays inside a very small window", function()
    local point = space_nav.title_bar_point({ x = 0, y = 0, w = 4, h = 10 })
    assert.same({ x = 2, y = 5 }, point)
  end)

  it("drags one pixel to the right of the grab point", function()
    local point = space_nav.drag_point({ x = 190, y = 68 })
    assert.same({ x = 191, y = 68 }, point)
  end)
end)

describe("space_nav.removal_direction", function()
  it("switches left before removing, or right from the first Space", function()
    assert.equals("left", space_nav.removal_direction(IDS, 30))
    assert.equals("left", space_nav.removal_direction(IDS, 40))
    assert.equals("right", space_nav.removal_direction(IDS, 10))
  end)

  it("refuses to remove the only Space or an unknown one", function()
    assert.is_nil(space_nav.removal_direction({ 10 }, 10))
    assert.is_nil(space_nav.removal_direction(IDS, 99))
  end)
end)

describe("space_nav.indicator_text", function()
  it("marks the current Space", function()
    assert.equals("..#.", space_nav.indicator_text(IDS, 30, "#", "."))
  end)

  it("is empty without Spaces", function()
    assert.equals("", space_nav.indicator_text({}, 1, "#", "."))
  end)
end)

describe("space_nav.flash_layout", function()
  it("lays out one square per Space, left to right, inside the panel", function()
    local layout = space_nav.flash_layout(3)
    assert.equals(3, #layout.boxes)
    assert.is_true(layout.boxes[2].x > layout.boxes[1].x + layout.boxes[1].w)
    local last = layout.boxes[3]
    assert.is_true(last.x + last.w < layout.width)
    assert.equals(layout.boxes[1].y, layout.boxes[3].y)
  end)

  it("grows with the number of Spaces", function()
    assert.is_true(space_nav.flash_layout(5).width > space_nav.flash_layout(2).width)
  end)

  it("handles no Spaces", function()
    assert.equals(0, #space_nav.flash_layout(0).boxes)
  end)
end)
