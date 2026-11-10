local window_state = require("rakuen.core.window_state")

describe("window_state", function()
  local screen = { x = 0, y = 25, w = 1440, h = 800 }
  local original = { x = 200, y = 100, w = 600, h = 400 }

  local function state_after_applying(target)
    return { original = original, requested = target, applied = target }
  end

  describe("decide_toggle", function()
    it("applies the target and remembers the current frame", function()
      local decision = window_state.decide_toggle(original, screen, nil)
      assert.equals("apply", decision.action)
      assert.same(screen, decision.frame)
      assert.same(original, decision.original)
    end)

    it("restores the original frame when pressed again", function()
      local decision = window_state.decide_toggle(screen, screen, state_after_applying(screen))
      assert.equals("restore", decision.action)
      assert.same(original, decision.frame)
    end)

    it("keeps the first original when switching from one target to another", function()
      local left = { x = 0, y = 25, w = 720, h = 800 }
      local decision = window_state.decide_toggle(screen, left, state_after_applying(screen))
      assert.equals("apply", decision.action)
      assert.same(original, decision.original)
    end)

    it("does nothing when the window is already at the target with no history", function()
      local decision = window_state.decide_toggle(screen, screen, nil)
      assert.equals("none", decision.action)
    end)

    it("toggles back even when the app refused part of the size", function()
      local requested = { x = 0, y = 25, w = 720, h = 800 }
      local applied = { x = 0, y = 25, w = 900, h = 800 }
      local state = { original = original, requested = requested, applied = applied }
      local decision = window_state.decide_toggle(applied, requested, state)
      assert.equals("restore", decision.action)
    end)

    it("ignores a stale state after the user moved the window", function()
      local moved = { x = 300, y = 300, w = 500, h = 500 }
      local decision = window_state.decide_toggle(moved, screen, state_after_applying(screen))
      assert.equals("apply", decision.action)
      assert.same(moved, decision.original)
    end)
  end)

  describe("decide_apply", function()
    it("applies the target", function()
      local decision = window_state.decide_apply(original, screen, nil)
      assert.equals("apply", decision.action)
    end)

    it("does nothing when the window is already there", function()
      local decision = window_state.decide_apply(screen, screen, state_after_applying(screen))
      assert.equals("none", decision.action)
    end)
  end)

  describe("decide_restore", function()
    it("restores the original frame", function()
      local decision = window_state.decide_restore(screen, state_after_applying(screen))
      assert.equals("restore", decision.action)
      assert.same(original, decision.frame)
    end)

    it("does nothing without a state", function()
      assert.equals("none", window_state.decide_restore(screen, nil).action)
    end)

    it("does nothing with a stale state", function()
      local moved = { x = 5, y = 5, w = 300, h = 300 }
      assert.equals("none", window_state.decide_restore(moved, state_after_applying(screen)).action)
    end)
  end)
end)
