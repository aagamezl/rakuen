local applications = require("rakuen.modules.applications")
local hs_mock = require("spec.helpers.hs_mock")
local logger = require("rakuen.core.logger")

describe("applications module", function()
  local mock_hs
  local on_destroyed
  local killed
  local lines

  local function fake_window(standard)
    return {
      isStandard = function()
        return standard
      end,
      isMinimized = function()
        return false
      end,
      isFullScreen = function()
        return false
      end,
    }
  end

  local function fake_app(bundle_id, windows)
    return {
      isRunning = function()
        return true
      end,
      bundleID = function()
        return bundle_id
      end,
      kind = function()
        return 1
      end,
      isHidden = function()
        return false
      end,
      allWindows = function()
        return windows
      end,
      kill = function()
        table.insert(killed, bundle_id)
      end,
    }
  end

  local function start(rules)
    applications.on_load(
      logger.new("info", function(line)
        table.insert(lines, line)
      end),
      rules or applications.rules
    )
  end

  local function close_window_of(app)
    on_destroyed({
      application = function()
        return app
      end,
    }, "App")
  end

  before_each(function()
    mock_hs = hs_mock.install()
    killed = {}
    lines = {}
    mock_hs.timer = {
      doAfter = function(_, callback)
        callback()
      end,
    }
    mock_hs.window = {
      filter = {
        windowDestroyed = "windowDestroyed",
        new = function()
          return {
            subscribe = function(_, _, callback)
              on_destroyed = callback
            end,
          }
        end,
      },
    }
  end)

  after_each(function()
    hs_mock.uninstall()
  end)

  it("has one rule without a chord, with Finder disabled by default", function()
    local rule = applications.rules[1]

    assert.equals(1, #applications.rules)
    assert.equals("none", rule.to)
    assert.same("com.apple.finder", rule.applications.disable[1])
  end)

  it("quits an app after its last window closes, gracefully", function()
    start()
    close_window_of(fake_app("com.apple.TextEdit", {}))

    assert.same({ "com.apple.TextEdit" }, killed)
    assert.is_truthy(lines[1]:find("quitting com.apple.TextEdit", 1, true))
  end)

  it("keeps an app that still has a window", function()
    start()
    close_window_of(fake_app("com.apple.TextEdit", { fake_window(true) }))

    assert.same({}, killed)
  end)

  it("keeps Finder", function()
    start()
    close_window_of(fake_app("com.apple.finder", {}))

    assert.same({}, killed)
  end)

  it("starts no watcher when the binding is disabled", function()
    on_destroyed = nil
    start({})

    assert.is_nil(on_destroyed)
  end)
end)
