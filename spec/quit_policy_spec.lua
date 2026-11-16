local quit_policy = require("rakuen.core.quit_policy")

describe("quit_policy", function()
  local app = { bundle_id = "com.apple.TextEdit", regular = true, hidden = false }
  local filter = { disable = { "com.apple.finder" } }

  describe("count_windows", function()
    it("counts standard, minimized and fullscreen windows", function()
      local windows = {
        { standard = true },
        { minimized = true },
        { fullscreen = true },
      }

      assert.equals(3, quit_policy.count_windows(windows))
    end)

    it("ignores sheets and panels", function()
      assert.equals(0, quit_policy.count_windows({ { standard = false } }))
    end)
  end)

  describe("should_quit", function()
    it("quits a regular app with no windows", function()
      assert.is_true(quit_policy.should_quit(app, 0, filter))
    end)

    it("keeps an app that still has a window", function()
      assert.is_false(quit_policy.should_quit(app, 1, filter))
    end)

    it("keeps apps on the disable list", function()
      local finder = { bundle_id = "com.apple.finder", regular = true, hidden = false }

      assert.is_false(quit_policy.should_quit(finder, 0, filter))
    end)

    it("keeps background and menu bar apps", function()
      local agent = { bundle_id = "com.example.agent", regular = false, hidden = false }

      assert.is_false(quit_policy.should_quit(agent, 0, filter))
    end)

    it("keeps hidden apps, which report no windows", function()
      local hidden = { bundle_id = app.bundle_id, regular = true, hidden = true }

      assert.is_false(quit_policy.should_quit(hidden, 0, filter))
    end)

    it("keeps an app without a bundle id", function()
      local unknown = { regular = true, hidden = false }

      assert.is_false(quit_policy.should_quit(unknown, 0, filter))
    end)

    it("honors an enable list", function()
      local only_safari = { enable = { "com.apple.Safari" } }

      assert.is_false(quit_policy.should_quit(app, 0, only_safari))
    end)
  end)
end)
