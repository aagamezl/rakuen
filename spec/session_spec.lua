local config = require("rakuen.core.config")
local hs_mock = require("spec.helpers.hs_mock")
local registry = require("rakuen.core.registry")
local session = require("rakuen.modules.session")

local function find_rule(chord)
  for _, rule in ipairs(session.rules) do
    if rule.to == chord then
      return rule
    end
  end
  return nil
end

describe("session module", function()
  local mock_hs
  local calls
  local answer

  before_each(function()
    mock_hs = hs_mock.install()
    calls = {}
    answer = "Cancel"
    -- Handlers run on a timer outside the event tap; run it at once here.
    mock_hs.timer = {
      doAfter = function(_, callback)
        callback()
      end,
    }
    mock_hs.alert = {
      show = function(message)
        table.insert(calls, "alert: " .. message)
      end,
    }
    mock_hs.dialog = {
      blockAlert = function()
        return answer
      end,
    }
    mock_hs.caffeinate = {
      lockScreen = function()
        table.insert(calls, "lock")
      end,
      logOut = function()
        table.insert(calls, "logout")
      end,
      shutdownSystem = function()
        table.insert(calls, "shutdown")
      end,
    }
  end)

  after_each(function()
    hs_mock.uninstall()
  end)

  it("does not conflict with any other module", function()
    local rules = registry.new()
    assert.has_no.errors(function()
      for _, name in ipairs(config.MODULE_NAMES) do
        rules:add_all(name, require("rakuen.modules." .. name).rules)
      end
    end)
  end)

  it("locks the screen", function()
    find_rule("Cmd+L").action()
    assert.same({ "lock" }, calls)
  end)

  it("gives browsers Ctrl+L for the location bar, and only browsers", function()
    local rule = find_rule("Ctrl+L")
    assert.same({ mods = { "cmd" }, key = "l" }, rule.action)
    assert.same({ "com.apple.Safari" }, { rule.applications.enable[1] })
    assert.is_nil(rule.applications.disable)
  end)

  it("logs out without its own dialog, macOS asks", function()
    find_rule("Cmd+Opt+L").action()
    assert.same({ "logout" }, calls)
  end)

  it("shuts down only after confirmation", function()
    find_rule("Cmd+Opt+F4").action()
    assert.same({}, calls)

    answer = "Shut Down"
    find_rule("Cmd+Opt+F4").action()
    assert.same({ "shutdown" }, calls)
  end)

  it("alerts instead of raising when the action fails", function()
    mock_hs.caffeinate.lockScreen = function()
      error("no session")
    end
    find_rule("Cmd+L").action()
    assert.equals(1, #calls)
  end)

  it("posts VoiceOver's shortcut for the screen reader", function()
    assert.same({ mods = { "cmd" }, key = "f5" }, find_rule("Opt+Cmd+S").action)
  end)

  it("leaves the native zoom shortcuts alone", function()
    assert.is_nil(find_rule("Opt+Cmd+8"))
    assert.is_nil(find_rule("Opt+Cmd+="))
    assert.is_nil(find_rule("Opt+Cmd+-"))
  end)
end)
