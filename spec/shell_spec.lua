local config = require("rakuen.core.config")
local hs_mock = require("spec.helpers.hs_mock")
local registry = require("rakuen.core.registry")
local shell = require("rakuen.modules.shell")

local function find_rule(chord)
  for _, rule in ipairs(shell.rules) do
    if rule.to == chord then
      return rule
    end
  end
  return nil
end

describe("shell module", function()
  local mock_hs
  local alerts

  before_each(function()
    mock_hs = hs_mock.install()
    alerts = {}
    -- Handlers run on a timer outside the event tap; run it at once here.
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

  it("posts Spotlight for the run dialog", function()
    assert.same({ mods = { "cmd" }, key = "space" }, find_rule("Opt+F2").action)
  end)

  it("leaves overview up and down alone, since Spaces are switched by macOS", function()
    assert.is_nil(find_rule("Cmd+Opt+Up"))
    assert.is_nil(find_rule("Cmd+Opt+Down"))
  end)

  it("opens Apps, falling back to Launchpad, then alerts", function()
    local opened = {}
    mock_hs.application.launchOrFocus = function(name)
      table.insert(opened, name)
      return name == "Launchpad"
    end
    find_rule("Cmd+A").action()
    assert.same({ "Apps", "Launchpad" }, opened)
    assert.equals(0, #alerts)

    mock_hs.application.launchOrFocus = function()
      return false
    end
    find_rule("Cmd+A").action()
    assert.equals(1, #alerts)
  end)

  it("opens System Settings for quick settings", function()
    local opened
    mock_hs.application.launchOrFocus = function(name)
      opened = name
      return true
    end
    find_rule("Cmd+S").action()
    assert.equals("System Settings", opened)
  end)

  local function fake(attributes, children, on_action)
    return {
      attributeValue = function(_, name)
        if name == "AXChildren" then
          return children
        end
        return attributes[name]
      end,
      performAction = function(_, action)
        on_action(action)
      end,
    }
  end

  local function install_control_center(app_element)
    mock_hs.application.get = function()
      return {}
    end
    mock_hs.axuielement = {
      applicationElement = function()
        return app_element
      end,
    }
  end

  it("presses the clock item in the extras menu bar of the menu bar agent", function()
    local pressed
    local requested
    local clock = fake({ AXIdentifier = "com.apple.menuextra.clock" }, nil, function(action)
      pressed = action
    end)
    local battery = fake({ AXIdentifier = "com.apple.menuextra.battery" }, nil, function() end)
    local extras = fake(
      {},
      { fake({}, { battery }, function() end), fake({}, { clock }, function() end) },
      function() end
    )
    -- The extras bar is an attribute, not a child of the app.
    mock_hs.screen = {
      mainScreen = function()
        return {
          frame = function()
            return { x = 0, y = 0, w = 1000, h = 800 }
          end,
        }
      end,
    }
    install_control_center(fake({ AXExtrasMenuBar = extras }, {}, function() end))
    mock_hs.application.get = function(bundle_id)
      requested = bundle_id
      return {}
    end

    find_rule("Cmd+M").action()
    assert.equals("com.apple.MenuBarAgent", requested)
    assert.equals("AXPress", pressed)
    assert.equals(0, #alerts)
  end)

  it("clicks the clock like a user and restores the pointer", function()
    local events = {}
    local pointer = { x = 10, y = 10 }
    local clock = fake(
      {
        AXIdentifier = "com.apple.menuextra.clock",
        AXFrame = { x = 900, y = 0, w = 60, h = 24 },
      },
      nil,
      function()
        error("should click, not press")
      end
    )
    mock_hs.screen = {
      mainScreen = function()
        return {
          frame = function()
            return { x = 0, y = 0, w = 1000, h = 800 }
          end,
        }
      end,
    }
    mock_hs.mouse = {
      getCurrentScreen = function()
        return nil
      end,
      absolutePosition = function(point)
        if point ~= nil then
          pointer = point
        end
        return pointer
      end,
    }
    mock_hs.eventtap.event = {
      types = { leftMouseDown = "down", leftMouseUp = "up" },
      newMouseEvent = function(event_type, point)
        return {
          post = function()
            table.insert(events, { event_type, point.x, point.y })
          end,
        }
      end,
    }
    install_control_center(
      fake({ AXExtrasMenuBar = fake({}, { clock }, function() end) }, {}, function() end)
    )

    find_rule("Cmd+M").action()
    assert.same({ { "down", 930, 12 }, { "up", 930, 12 } }, events)
    assert.same({ x = 10, y = 10 }, pointer)
  end)

  it("picks the clock on the current display when there are several", function()
    local left = fake({ AXFrame = { x = 900, y = 0, w = 60, h = 24 } }, nil, function() end)
    local right = fake({ AXFrame = { x = 1900, y = 0, w = 60, h = 24 } }, nil, function() end)
    local picked = shell.pick_item_for_screen(
      { left, right },
      { x = 1000, y = 0, w = 1000, h = 800 }
    )
    assert.equals(right, picked)
  end)

  it("falls back to the first clock when none is on the display", function()
    local only = fake({ AXFrame = { x = 5000, y = 0, w = 60, h = 24 } }, nil, function() end)
    assert.equals(only, shell.pick_item_for_screen({ only }, { x = 0, y = 0, w = 100, h = 100 }))
    assert.is_nil(shell.pick_item_for_screen({}, { x = 0, y = 0, w = 100, h = 100 }))
  end)

  it("binds the message tray to Cmd+M only", function()
    assert.is_nil(find_rule("Cmd+V"))
  end)

  it("alerts when the menu bar agent is not running", function()
    mock_hs.application.get = function()
      return nil
    end
    find_rule("Cmd+M").action()
    assert.equals(1, #alerts)
  end)

  it("alerts when the Notification Center item is missing", function()
    install_control_center(fake({}, {}, function() end))
    find_rule("Cmd+M").action()
    assert.equals(1, #alerts)
  end)

  it("captures the focused window with screencapture", function()
    local task_args
    local callback
    mock_hs.window = {
      focusedWindow = function()
        return {
          id = function()
            return 99
          end,
        }
      end,
    }
    mock_hs.task = {
      new = function(executable, on_exit, arguments)
        task_args = { executable = executable, arguments = arguments }
        callback = on_exit
        return {
          start = function() end,
        }
      end,
    }
    find_rule("Opt+F13").action()
    assert.equals("/usr/sbin/screencapture", task_args.executable)
    assert.equals("-l", task_args.arguments[1])
    assert.equals("99", task_args.arguments[2])

    callback(1)
    assert.equals(1, #alerts)
  end)

  it("alerts when there is no window to capture", function()
    mock_hs.window = {
      focusedWindow = function()
        return nil
      end,
    }
    find_rule("Opt+F13").action()
    assert.equals(1, #alerts)
  end)
end)
