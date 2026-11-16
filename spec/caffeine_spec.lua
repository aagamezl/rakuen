local caffeine = require("rakuen.modules.caffeine")
local caffeine_icon = require("rakuen.ui.caffeine_icon")
local menubar = require("rakuen.ui.menubar")
local hs_mock = require("spec.helpers.hs_mock")

describe("caffeine module", function()
  local mock_hs
  local held
  local alerts
  local menu

  before_each(function()
    mock_hs = hs_mock.install()
    held = false
    alerts = {}
    mock_hs.timer = {
      doAfter = function(_, callback)
        callback()
      end,
    }
    mock_hs.alert = {
      show = function(message)
        table.insert(alerts, message)
      end,
    }
    mock_hs.caffeinate = {
      get = function()
        return held
      end,
      set = function(_, value)
        held = value
      end,
    }
    menu = {
      setIcon = function() end,
      setTitle = function() end,
      setTooltip = function(_, text)
        menu.tooltip = text
      end,
      setMenu = function(_, builder)
        menu.builder = builder
      end,
      delete = function() end,
    }
    mock_hs.menubar = {
      new = function()
        return menu
      end,
    }
    -- hs.canvas is missing here, so the icon falls back to text.
  end)

  after_each(function()
    menubar.reset()
    hs_mock.uninstall()
  end)

  it("has one rule on Ctrl+Cmd+K", function()
    assert.equals(1, #caffeine.rules)
    assert.equals("Ctrl+Cmd+K", caffeine.rules[1].to)
  end)

  it("toggles on and off with the chord and says so", function()
    caffeine.rules[1].action()
    assert.is_true(held)

    caffeine.rules[1].action()
    assert.is_false(held)
    assert.same({ "Caffeine: Awake", "Caffeine: Off" }, alerts)
  end)

  it("toggles from its entry in the Rakuen menu", function()
    caffeine.on_load(nil, caffeine.rules)
    local entry = menu.builder()[1]
    assert.equals("Caffeine", entry.title)
    assert.is_true(entry.checked)
    entry.fn()

    -- It starts awake, so the first click lets the Mac sleep.
    assert.is_false(held)
    assert.equals("Rakuen. " .. caffeine.tooltip(false), menu.tooltip)
  end)

  it("starts awake when loaded", function()
    caffeine.on_load(nil, caffeine.rules)

    assert.is_true(held)
  end)

  it("adds no menu bar item when the binding is disabled", function()
    mock_hs.menubar.new = function()
      error("must not be called")
    end

    assert.has_no.errors(function()
      caffeine.on_load(nil, {})
    end)
  end)

  it("draws steam only while active", function()
    assert.equals(3, #caffeine_icon.elements(false))
    assert.equals(3 + #caffeine_icon.STEAM_X, #caffeine_icon.elements(true))
  end)

  it("fills the cup only while active", function()
    assert.equals("stroke", caffeine_icon.elements(false)[1].action)
    assert.equals("strokeAndFill", caffeine_icon.elements(true)[1].action)
  end)
end)
