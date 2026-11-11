local hs_mock = require("spec.helpers.hs_mock")
local mission_control = require("rakuen.core.mission_control")
local registry = require("rakuen.core.registry")
local workspaces = require("rakuen.modules.workspaces")

local function find_rule(chord)
  for _, rule in ipairs(workspaces.rules) do
    if rule.to == chord then
      return rule
    end
  end
  return nil
end

describe("workspaces module", function()
  local original_add_space = mission_control.add_space
  local original_remove_space = mission_control.remove_space
  local mock_hs
  local alerts
  local moves
  local current
  local posted

  before_each(function()
    mock_hs = hs_mock.install()
    alerts = {}
    moves = {}
    current = 30
    posted = {}

    mock_hs.screen = {
      mainScreen = function()
        return {
          id = function()
            return 7
          end,
        }
      end,
    }
    mock_hs.spaces = {
      spacesForScreen = function()
        return { 10, 20, 30, 40 }
      end,
      activeSpaceOnScreen = function()
        return current
      end,
      moveWindowToSpace = function(_, space_id)
        table.insert(moves, space_id)
        return true
      end,
    }
    mock_hs.window = {
      focusedWindow = function()
        return {}
      end,
    }
    mock_hs.alert = {
      show = function(message)
        table.insert(alerts, message)
      end,
    }
    -- Run delayed presses at once and record the chord each one posts.
    mock_hs.timer = {
      doAfter = function(_, callback)
        callback()
      end,
    }
    mock_hs.eventtap.event = {
      properties = { eventSourceUserData = "marker" },
      newKeyEvent = function(modifiers, key, is_down)
        return {
          setProperty = function() end,
          post = function()
            if is_down then
              table.insert(posted, { modifiers = modifiers, key = key })
            end
          end,
        }
      end,
    }
  end)

  after_each(function()
    mission_control.add_space = original_add_space
    mission_control.remove_space = original_remove_space
    hs_mock.uninstall()
  end)

  it("registers without conflicts or malformed rules", function()
    local rules = registry.new()
    assert.has_no.errors(function()
      rules:add_all("workspaces", workspaces.rules)
    end)
  end)

  it("leaves previous and next space to macOS", function()
    assert.is_nil(find_rule("Cmd+PageUp"))
    assert.is_nil(find_rule("Cmd+PageDown"))
  end)

  it("goes to the first Space by pressing Ctrl+Cmd+Left once per Space", function()
    find_rule("Cmd+Home").action()
    assert.equals(2, #posted)
    assert.same({ "ctrl", "cmd", "fn" }, posted[1].modifiers)
    assert.equals("left", posted[1].key)
  end)

  it("does nothing at the last Space", function()
    current = 40
    find_rule("Cmd+End").action()
    assert.equals(0, #posted)
  end)

  it("moves the window by dragging its title bar while switching Space", function()
    local mouse_events = {}
    local frames = {}
    local win = {
      application = function()
        return {
          bundleID = function()
            return "com.example.app"
          end,
        }
      end,
      unminimize = function() end,
      raise = function() end,
      focus = function() end,
      isVisible = function()
        return true
      end,
      frame = function()
        return { x = 100, y = 50, w = 400, h = 300 }
      end,
      setFrame = function(_, frame)
        table.insert(frames, frame)
      end,
    }
    mock_hs.window.focusedWindow = function()
      return win
    end
    mock_hs.mouse = {
      absolutePosition = function() end,
    }
    mock_hs.eventtap.event.properties.mouseEventDeltaX = "delta_x"
    mock_hs.eventtap.event.types = {
      leftMouseDown = "down",
      leftMouseDragged = "drag",
      leftMouseUp = "up",
    }
    mock_hs.eventtap.event.newMouseEvent = function(event_type)
      return {
        setProperty = function() end,
        post = function()
          table.insert(mouse_events, event_type)
        end,
      }
    end

    find_rule("Cmd+Shift+PageDown").action()

    assert.same({ "down", "drag", "up" }, mouse_events)
    assert.equals(1, #posted)
    assert.equals("right", posted[1].key)
    assert.same({ { x = 100, y = 50, w = 400, h = 300 } }, frames)
  end)

  it("alerts instead of raising when Spaces are unavailable", function()
    mock_hs.spaces = nil
    assert.has_no.errors(function()
      find_rule("Cmd+Home").action()
    end)
    assert.equals(1, #alerts)
  end)

  it("also answers Cmd+Shift+Opt and Ctrl+Shift+Opt arrows", function()
    assert.is_not_nil(find_rule("Cmd+Shift+Opt+Left"))
    assert.is_not_nil(find_rule("Ctrl+Shift+Opt+Right"))
  end)

  describe("insert and remove space", function()
    local timers
    local closes
    local held
    local removals

    before_each(function()
      timers = {}
      closes = {}
      held = {}
      mock_hs.spaces.addSpaceToScreen = function()
        return true
      end
      removals = {}
      mission_control.remove_space = function(display_id, index, on_done)
        table.insert(removals, { display_id = display_id, index = index })
        on_done(true)
      end
      mock_hs.menubar = nil
      mock_hs.spaces.closeMissionControl = function()
        table.insert(closes, true)
      end
      mock_hs.eventtap.checkKeyboardModifiers = function()
        return held
      end
      mock_hs.timer.doAfter = function(_, callback)
        table.insert(timers, callback)
      end
    end)

    it("adds a Space through Mission Control", function()
      local added = false
      mission_control.add_space = function(on_done)
        added = true
        on_done(true)
      end
      find_rule("Ctrl+Cmd+=").action()
      assert.is_true(added)
      assert.equals(0, #alerts)
    end)

    it("alerts when the Add Space button cannot be pressed", function()
      mission_control.add_space = function(on_done)
        on_done(false, "not found")
      end
      find_rule("Ctrl+Cmd+=").action()
      assert.equals(1, #alerts)
    end)

    it("waits for the modifier keys to be released before using Mission Control", function()
      local added = false
      mission_control.add_space = function()
        added = true
      end
      held = { ctrl = true, cmd = true }
      find_rule("Ctrl+Cmd+=").action()
      assert.is_false(added)

      held = {}
      timers[1]()
      assert.is_true(added)
    end)

    it("switches away first, then removes the old Space once it has left it", function()
      find_rule("Ctrl+Cmd+-").action()
      timers[1]()
      assert.equals("left", posted[1].key)

      -- Still on the old Space: keeps polling.
      timers[2]()
      assert.same({}, removals)

      current = 20
      timers[3]()
      timers[4]()
      assert.same({ { display_id = 7, index = 3 } }, removals)
    end)

    it("does not remove a Space it could not leave", function()
      find_rule("Ctrl+Cmd+-").action()
      while #timers > 0 do
        table.remove(timers, 1)()
      end
      assert.same({}, removals)
      assert.equals(1, #alerts)
    end)

    it("alerts when Mission Control cannot remove the Space", function()
      mission_control.remove_space = function(_, _, on_done)
        on_done(false, "not found")
      end
      find_rule("Ctrl+Cmd+-").action()
      current = 20
      while #timers > 0 do
        table.remove(timers, 1)()
      end
      assert.equals(1, #alerts)
    end)

    it("refuses to remove the only Space", function()
      mock_hs.spaces.spacesForScreen = function()
        return { 30 }
      end
      find_rule("Ctrl+Cmd+-").action()
      assert.equals(1, #alerts)
      assert.equals(0, #timers)
    end)
  end)
end)
