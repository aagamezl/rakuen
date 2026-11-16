local clipboard_history = require("rakuen.core.clipboard_history")

describe("clipboard_history", function()
  it("keeps the newest entry first", function()
    local history = clipboard_history.new()
    history:add("one")
    history:add("two")

    assert.same({ "two", "one" }, history:list())
  end)

  it("moves a repeated entry to the front without duplicating it", function()
    local history = clipboard_history.new()
    history:add("one")
    history:add("two")
    assert.is_true(history:add("one"))

    assert.same({ "one", "two" }, history:list())
    assert.is_false(history:add("one"))
  end)

  it("ignores blank and non-text values", function()
    local history = clipboard_history.new()

    assert.is_false(history:add("  \n"))
    assert.is_false(history:add(nil))
    assert.same({}, history:list())
  end)

  it("drops the oldest entries past the limit", function()
    local history = clipboard_history.new(2)
    history:add("one")
    history:add("two")
    history:add("three")

    assert.same({ "three", "two" }, history:list())
  end)

  it("removes one entry", function()
    local history = clipboard_history.new()
    history:add("one")
    history:add("two")

    assert.is_true(history:remove("one"))
    assert.is_false(history:remove("one"))
    assert.same({ "two" }, history:list())
  end)

  it("clears", function()
    local history = clipboard_history.new()
    history:add("one")
    history:clear()

    assert.same({}, history:list())
  end)

  it("previews on one line and cuts long text", function()
    assert.equals("a b c", clipboard_history.preview("  a\n b\tc \n"))

    local preview = clipboard_history.preview(string.rep("x", 200))
    assert.equals(80, #preview)
    assert.equals("...", preview:sub(-3))
  end)
end)
