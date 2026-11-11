local shortcut_check = require("rakuen.core.shortcut_check")

local function hotkey(keycode, modifiers, enabled)
  return {
    enabled = enabled ~= false,
    value = { parameters = { 65535, keycode, modifiers }, type = "standard" },
  }
end

local function moved_hotkeys()
  return {
    ["79"] = hotkey(123, 9699328),
    ["81"] = hotkey(124, 9699328),
    ["32"] = hotkey(126, 9699328),
    ["33"] = hotkey(125, 9699328),
  }
end

describe("shortcut_check.problems", function()
  it("reports nothing when all four shortcuts are on Ctrl+Cmd+Arrow", function()
    assert.same({}, shortcut_check.problems(moved_hotkeys()))
  end)

  it("reports shortcuts still on Ctrl+Arrow", function()
    local hotkeys = moved_hotkeys()
    hotkeys["79"] = hotkey(123, 8650752)
    assert.same({ "Move left a space" }, shortcut_check.problems(hotkeys))
  end)

  it("reports disabled and missing shortcuts", function()
    local hotkeys = moved_hotkeys()
    hotkeys["32"] = hotkey(126, 9699328, false)
    hotkeys["33"] = nil
    assert.same({ "Mission Control", "Application windows" }, shortcut_check.problems(hotkeys))
  end)

  it("reports everything for an empty table", function()
    assert.equals(4, #shortcut_check.problems({}))
  end)
end)
