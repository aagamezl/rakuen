local window_cycle = require("rakuen.core.window_cycle")

local FORWARD = window_cycle.FORWARD
local BACKWARD = window_cycle.BACKWARD

describe("window_cycle.next_id", function()
  it("returns nil for an empty list", function()
    assert.is_nil(window_cycle.next_id({}, 1, FORWARD))
  end)

  it("moves forward in sorted order and wraps", function()
    assert.equals(5, window_cycle.next_id({ 9, 2, 5 }, 2, FORWARD))
    assert.equals(2, window_cycle.next_id({ 9, 2, 5 }, 9, FORWARD))
  end)

  it("moves backward and wraps", function()
    assert.equals(2, window_cycle.next_id({ 9, 2, 5 }, 5, BACKWARD))
    assert.equals(9, window_cycle.next_id({ 9, 2, 5 }, 2, BACKWARD))
  end)

  it("starts at the first or last id when the current one is missing", function()
    assert.equals(2, window_cycle.next_id({ 9, 2, 5 }, 7, FORWARD))
    assert.equals(9, window_cycle.next_id({ 9, 2, 5 }, 7, BACKWARD))
    assert.equals(2, window_cycle.next_id({ 9, 2, 5 }, nil, FORWARD))
  end)

  it("returns the same id for a single window", function()
    assert.equals(4, window_cycle.next_id({ 4 }, 4, FORWARD))
  end)

  it("does not reorder the caller's list", function()
    local ids = { 9, 2, 5 }
    window_cycle.next_id(ids, 2, FORWARD)
    assert.same({ 9, 2, 5 }, ids)
  end)
end)

describe("window_cycle.app_switch_target", function()
  local entries = {
    { app = "a", window = 1 },
    { app = "a", window = 2 },
    { app = "b", window = 3 },
    { app = "c", window = 4 },
    { app = "b", window = 5 },
  }

  it("goes forward to the most recent window of another app", function()
    assert.equals(3, window_cycle.app_switch_target(entries, FORWARD))
  end)

  it("goes backward to the least recently used app", function()
    assert.equals(3, window_cycle.app_switch_target(entries, BACKWARD))
    local other =
      { { app = "a", window = 1 }, { app = "b", window = 2 }, { app = "c", window = 3 } }
    assert.equals(3, window_cycle.app_switch_target(other, BACKWARD))
  end)

  it("returns nil with no windows or a single app", function()
    assert.is_nil(window_cycle.app_switch_target({}, FORWARD))
    local single = { { app = "a", window = 1 }, { app = "a", window = 2 } }
    assert.is_nil(window_cycle.app_switch_target(single, FORWARD))
    assert.is_nil(window_cycle.app_switch_target(single, BACKWARD))
  end)
end)
