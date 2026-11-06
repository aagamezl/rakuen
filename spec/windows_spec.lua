local fake_window = require("spec.helpers.fake_window")
local hs_mock = require("spec.helpers.hs_mock")
local keycombo = require("rakuen.core.keycombo")
local registry = require("rakuen.core.registry")
local windows = require("rakuen.modules.windows")

local function find_rule(description)
  for _, rule in ipairs(windows.rules) do
    if rule.description == description then
      return rule
    end
  end
  return nil
end

describe("windows module", function()
  local area = { x = 0, y = 25, w = 1440, h = 800 }
  local start = { x = 200, y = 100, w = 600, h = 400 }
  local win
  local alerts
  local mock_hs

  before_each(function()
    mock_hs = hs_mock.install()
    win = fake_window.new(start, fake_window.screen(area))
    alerts = {}
    mock_hs.window = {
      focusedWindow = function()
        return win
      end,
    }
    mock_hs.alert = {
      show = function(message)
        table.insert(alerts, message)
      end,
    }
    windows.manager.states = {}
  end)

  after_each(function()
    hs_mock.uninstall()
  end)

  it("registers without conflicts or malformed rules", function()
    local rules = registry.new()
    assert.has_no.errors(function()
      rules:add_all("windows", windows.rules)
    end)
  end)

  it("has a unique description for every rule", function()
    local seen = {}
    for _, rule in ipairs(windows.rules) do
      assert.is_nil(seen[rule.description], rule.description)
      seen[rule.description] = true
    end
  end)

  it("does not use Ctrl, which belongs to editing and text navigation", function()
    for _, rule in ipairs(windows.rules) do
      local parsed = keycombo.parse(rule.to)
      for _, modifier in ipairs(parsed.modifiers) do
        assert.is_not.equals("ctrl", modifier, rule.description)
      end
    end
  end)

  it("listens for the GNOME window chords", function()
    local rules = registry.new()
    rules:add_all("windows", windows.rules)

    local expected = {
      ["alt+f4"] = "Close",
      ["alt+f10"] = "Toggle maximize",
      ["cmd+up"] = "Maximize",
      ["cmd+down"] = "Unmaximize",
      ["alt+f5"] = "Unmaximize (F5)",
      ["cmd+left"] = "Tile left",
      ["cmd+right"] = "Tile right",
      ["cmd+h"] = "Minimize",
      ["cmd+shift+left"] = "Move to display left",
      ["cmd+shift+right"] = "Move to display right",
      ["cmd+shift+up"] = "Move to display up",
      ["cmd+shift+down"] = "Move to display down",
      ["alt+f7"] = "Begin move",
      ["alt+f8"] = "Begin resize",
      ["alt+space"] = "Window action menu",
    }

    for chord, description in pairs(expected) do
      local rule = rules:find(chord, "com.apple.TextEdit")
      assert.is_not_nil(rule, chord)
      assert.equals(description, rule.description)
    end
  end)

  it("maximizes and unmaximizes the focused window", function()
    find_rule("Maximize").action()
    assert.same(area, win:frame())

    find_rule("Unmaximize").action()
    assert.same(start, win:frame())
  end)

  it("tiles the focused window left", function()
    find_rule("Tile left").action()
    assert.same({ x = 0, y = 25, w = 720, h = 800 }, win:frame())
  end)

  it("minimizes the focused window", function()
    find_rule("Minimize").action()
    assert.is_true(win.minimized)
  end)

  it("does nothing when there is no focused window", function()
    mock_hs.window.focusedWindow = function()
      return nil
    end
    assert.has_no.errors(function()
      find_rule("Maximize").action()
    end)
    assert.same({}, alerts)
  end)

  it("tells the user when a window cannot be resized", function()
    win = fake_window.new(area, fake_window.screen(area), { fullscreen = true })
    find_rule("Maximize").action()
    assert.same({ "This window cannot be moved or resized" }, alerts)
  end)

  it("does not raise when the window raises an error", function()
    win.setFrame = function()
      error("window refused")
    end
    assert.has_no.errors(function()
      find_rule("Maximize").action()
    end)
    assert.same({ "Rakuen: window action failed" }, alerts)
  end)
end)
