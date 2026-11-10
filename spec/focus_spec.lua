local hs_mock = require("spec.helpers.hs_mock")
local focus = require("rakuen.modules.focus")
local registry = require("rakuen.core.registry")

local function find_rule(description)
  for _, rule in ipairs(focus.rules) do
    if rule.description == description then
      return rule
    end
  end
  return nil
end

local function fake_app(bundle_id)
  return {
    bundleID = function()
      return bundle_id
    end,
    name = function()
      return bundle_id
    end,
  }
end

describe("focus module", function()
  local focused_id
  local ordered
  local focus_calls

  local function fake_win(id, bundle_id)
    return {
      id = function()
        return id
      end,
      isStandard = function()
        return true
      end,
      isVisible = function()
        return true
      end,
      isMinimized = function()
        return false
      end,
      application = function()
        return fake_app(bundle_id)
      end,
      focus = function()
        table.insert(focus_calls, id)
      end,
    }
  end

  before_each(function()
    local mock_hs = hs_mock.install()
    focus_calls = {}
    ordered = {
      fake_win(1, "a"),
      fake_win(2, "b"),
      fake_win(3, "a"),
    }
    focused_id = 1
    mock_hs.window = {
      orderedWindows = function()
        return ordered
      end,
      focusedWindow = function()
        for _, win in ipairs(ordered) do
          if win:id() == focused_id then
            return win
          end
        end
        return nil
      end,
    }
    mock_hs.alert = { show = function() end }
  end)

  after_each(function()
    hs_mock.uninstall()
  end)

  it("registers without conflicts or malformed rules", function()
    local rules = registry.new()
    assert.has_no.errors(function()
      rules:add_all("focus", focus.rules)
    end)
  end)

  it("cycles windows of the focused app only", function()
    find_rule("Cycle app windows").action()
    assert.same({ 3 }, focus_calls)
  end)

  it("cycles backward within the focused app", function()
    find_rule("Cycle app windows backward").action()
    assert.same({ 3 }, focus_calls)
  end)

  it("cycles across all apps in id order", function()
    find_rule("Cycle all windows").action()
    assert.same({ 2 }, focus_calls)
  end)

  it("switches to the most recent window of another app", function()
    find_rule("Switch applications").action()
    assert.same({ 2 }, focus_calls)
  end)
end)
