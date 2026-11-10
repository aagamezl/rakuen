local app_filter = require("rakuen.core.app_filter")

describe("app_filter", function()
  describe("allows", function()
    it("allows every app when the filter is missing or empty", function()
      assert.is_true(app_filter.allows(nil, "com.apple.finder"))
      assert.is_true(app_filter.allows({}, "com.apple.finder"))
      assert.is_true(app_filter.allows({ enable = {}, disable = {} }, "com.apple.finder"))
    end)

    it("allows only listed apps when enable is set", function()
      local filter = { enable = { "com.apple.finder" } }
      assert.is_true(app_filter.allows(filter, "com.apple.finder"))
      assert.is_false(app_filter.allows(filter, "com.apple.Safari"))
    end)

    it("blocks listed apps when only disable is set", function()
      local filter = { disable = { "com.apple.Terminal" } }
      assert.is_false(app_filter.allows(filter, "com.apple.Terminal"))
      assert.is_true(app_filter.allows(filter, "com.apple.Safari"))
    end)

    it("lets disable win over enable", function()
      local filter = { enable = { "a" }, disable = { "a" } }
      assert.is_false(app_filter.allows(filter, "a"))
    end)

    it("handles a missing frontmost app", function()
      assert.is_true(app_filter.allows({ disable = { "a" } }, nil))
      assert.is_false(app_filter.allows({ enable = { "a" } }, nil))
    end)
  end)

  describe("overlaps", function()
    it("overlaps when both filters are open", function()
      assert.is_true(app_filter.overlaps(nil, {}))
    end)

    it("overlaps when an enabled app is allowed by the open filter", function()
      assert.is_true(app_filter.overlaps({ enable = { "a" } }, nil))
    end)

    it("does not overlap when the open filter disables the enabled app", function()
      assert.is_false(app_filter.overlaps({ enable = { "a" } }, { disable = { "a" } }))
    end)

    it("does not overlap for disjoint enable lists", function()
      assert.is_false(app_filter.overlaps({ enable = { "a" } }, { enable = { "b" } }))
    end)

    it("overlaps for enable lists that share an app", function()
      assert.is_true(app_filter.overlaps({ enable = { "a", "b" } }, { enable = { "b" } }))
    end)
  end)
end)
