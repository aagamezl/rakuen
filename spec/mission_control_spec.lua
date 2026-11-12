local hs_mock = require("spec.helpers.hs_mock")
local mission_control = require("rakuen.core.mission_control")

local function fake_element(identifier, children, on_action)
  return {
    attributeValue = function(_, name)
      if name == "AXIdentifier" then
        return identifier
      end
      return children
    end,
    performAction = function(_, action)
      return on_action(action)
    end,
  }
end

describe("mission_control.find_element", function()
  it("finds a deeply nested element by identifier", function()
    local target = fake_element("mc.spaces.add")
    local root = fake_element("root", { fake_element("a", { fake_element("b", { target }) }) })
    assert.equals(target, mission_control.find_element(root, "mc.spaces.add"))
  end)

  it("returns nil when there is no such element", function()
    local root = fake_element("root", { fake_element("a") })
    assert.is_nil(mission_control.find_element(root, "mc.spaces.add"))
    assert.is_nil(mission_control.find_element(nil, "mc.spaces.add"))
  end)
end)

describe("mission_control.add_space", function()
  local mock_hs
  local escapes
  local opened
  local root
  local timers

  before_each(function()
    mock_hs = hs_mock.install()
    escapes = 0
    opened = 0
    timers = {}
    root = nil

    mock_hs.spaces = {
      openMissionControl = function()
        opened = opened + 1
      end,
    }
    mock_hs.application.applicationsForBundleID = function()
      return { {
        pid = function()
          return 1
        end,
      } }
    end
    mock_hs.axuielement = {
      applicationElementForPID = function()
        return root
      end,
    }
    mock_hs.timer = {
      doAfter = function(_, callback)
        table.insert(timers, callback)
      end,
    }
    mock_hs.eventtap.event = {
      properties = { eventSourceUserData = "marker" },
      newKeyEvent = function(_, key, is_down)
        return {
          setProperty = function() end,
          post = function()
            if is_down and key == "escape" then
              escapes = escapes + 1
            end
          end,
        }
      end,
    }
  end)

  after_each(function()
    hs_mock.uninstall()
  end)

  it("presses the button, then closes Mission Control with Escape", function()
    local pressed
    root = fake_element("root", {
      fake_element("mc.spaces.add", nil, function(action)
        pressed = action
        return true
      end),
    })
    local result = {}
    mission_control.add_space(1, function(succeeded, message)
      result = { succeeded, message }
    end)

    assert.equals(1, opened)
    assert.equals("AXPress", pressed)
    assert.equals(0, escapes)
    timers[1]()
    assert.equals(1, escapes)
    assert.is_true(result[1])
  end)

  it("keeps looking, then reports a missing button and still closes", function()
    root = fake_element("root", {})
    local result = {}
    mission_control.add_space(1, function(succeeded, message)
      result = { succeeded, message }
    end)

    -- Poll until the timeout; each poll schedules the next one.
    while #timers > 0 do
      table.remove(timers, 1)()
    end
    assert.is_false(result[1])
    assert.truthy(result[2]:find("not found"))
    assert.equals(1, escapes)
  end)

  it("reports a failed press", function()
    root = fake_element("root", {
      fake_element("mc.spaces.add", nil, function()
        return nil, "denied"
      end),
    })
    local result = {}
    mission_control.add_space(1, function(succeeded, message)
      result = { succeeded, message }
    end)
    timers[1]()
    assert.is_false(result[1])
    assert.equals("denied", result[2])
  end)
end)

describe("mission_control space lookup", function()
  local function display(display_id, space_count)
    local spaces = {}
    for index = 1, space_count do
      table.insert(spaces, fake_element("space" .. index))
    end
    local element = fake_element("mc.display", { fake_element("mc.spaces.list", spaces) })
    local base = element.attributeValue
    element.attributeValue = function(self, name)
      if name == "AXDisplayID" then
        return display_id
      end
      return base(self, name)
    end
    return element
  end

  it("finds the Space thumbnail by its position on the matching display", function()
    local root = fake_element("root", { display(1, 2), display(2, 3) })
    local element = mission_control.find_space_element(root, 2, 3)
    assert.equals("space3", element:attributeValue("AXIdentifier"))
  end)

  it("falls back to the only display", function()
    local root = fake_element("root", { display(5, 2) })
    local element = mission_control.find_space_element(root, 99, 2)
    assert.equals("space2", element:attributeValue("AXIdentifier"))
  end)

  it("returns nil when the display is ambiguous or the Space is missing", function()
    local ambiguous = fake_element("root", { display(1, 2), display(2, 2) })
    assert.is_nil(mission_control.find_space_element(ambiguous, 99, 1))

    local short = fake_element("root", { display(1, 2) })
    assert.is_nil(mission_control.find_space_element(short, 1, 5))
  end)
end)

describe("mission_control.remove_space", function()
  it("presses AXRemoveDesktop on the Space and closes Mission Control", function()
    local mock_hs = hs_mock.install()
    local actions = {}
    local escapes = 0
    local timers = {}
    local doomed = fake_element("space2", nil, function(action)
      table.insert(actions, action)
      return true
    end)
    local list = fake_element("mc.spaces.list", { fake_element("space1"), doomed })
    local display_element = fake_element("mc.display", { list })
    local root = fake_element("root", { display_element })

    mock_hs.spaces = { openMissionControl = function() end }
    mock_hs.application.applicationsForBundleID = function()
      return { {
        pid = function()
          return 1
        end,
      } }
    end
    mock_hs.axuielement = {
      applicationElementForPID = function()
        return root
      end,
    }
    mock_hs.timer = {
      doAfter = function(_, callback)
        table.insert(timers, callback)
      end,
    }
    mock_hs.eventtap.event = {
      properties = { eventSourceUserData = "marker" },
      newKeyEvent = function(_, key, is_down)
        return {
          setProperty = function() end,
          post = function()
            if is_down and key == "escape" then
              escapes = escapes + 1
            end
          end,
        }
      end,
    }

    local result
    mission_control.remove_space(1, 2, function(succeeded)
      result = succeeded
    end)
    timers[1]()

    assert.same({ "AXRemoveDesktop" }, actions)
    assert.equals(1, escapes)
    assert.is_true(result)
    hs_mock.uninstall()
  end)
end)

describe("mission_control.find_add_button", function()
  local function display_with_button(display_id, button)
    local element = fake_element("mc.display", { button })
    local base = element.attributeValue
    element.attributeValue = function(self, name)
      if name == "AXDisplayID" then
        return display_id
      end
      return base(self, name)
    end
    return element
  end

  it("takes the button of the requested display, not the first one", function()
    local first = fake_element("mc.spaces.add")
    local second = fake_element("mc.spaces.add")
    local root = fake_element("root", {
      display_with_button(1, first),
      display_with_button(2, second),
    })
    assert.equals(second, mission_control.find_add_button(root, 2))
    assert.equals(first, mission_control.find_add_button(root, 1))
  end)

  it("finds the button anywhere when there is a single display", function()
    local button = fake_element("mc.spaces.add")
    local root = fake_element("root", { fake_element("other", { button }) })
    assert.equals(button, mission_control.find_add_button(root, 5))
  end)

  it("does not guess between several displays", function()
    local root = fake_element("root", {
      display_with_button(1, fake_element("x")),
      display_with_button(2, fake_element("y")),
    })
    assert.is_nil(mission_control.find_add_button(root, 9))
  end)
end)
