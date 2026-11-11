local hs_mock = require("spec.helpers.hs_mock")
local space_indicator = require("rakuen.ui.space_indicator")

describe("space indicator", function()
  local titles
  local flashes
  local space_callback
  local deleted
  local elements
  local canvases_deleted

  before_each(function()
    local mock_hs = hs_mock.install()
    titles = {}
    flashes = {}
    deleted = false
    elements = {}
    canvases_deleted = 0

    local function watcher(callback_holder)
      return {
        start = function() end,
        stop = function() end,
        callback = callback_holder,
      }
    end

    mock_hs.menubar = {
      new = function()
        return {
          setTitle = function(_, title)
            table.insert(titles, title)
          end,
          delete = function()
            deleted = true
          end,
        }
      end,
    }
    mock_hs.screen = {
      mainScreen = function()
        return {
          frame = function()
            return { x = 0, y = 0, w = 1000, h = 800 }
          end,
        }
      end,
      watcher = {
        new = function()
          return watcher()
        end,
      },
    }
    mock_hs.spaces = {
      spacesForScreen = function()
        return { 10, 20, 30 }
      end,
      activeSpaceOnScreen = function()
        return 20
      end,
      watcher = {
        new = function(callback)
          space_callback = callback
          return watcher()
        end,
      },
    }
    mock_hs.timer = {
      doAfter = function() end,
    }
    mock_hs.canvas = {
      windowLevels = { overlay = 1 },
      windowBehaviors = { canJoinAllSpaces = 2 },
      new = function()
        table.insert(flashes, "canvas")
        local canvas = {}
        function canvas.level() end
        function canvas.behavior() end
        function canvas.show() end
        function canvas.delete()
          canvases_deleted = canvases_deleted + 1
        end
        function canvas.appendElements(_, element)
          table.insert(elements, element)
        end
        return canvas
      end,
    }
  end)

  after_each(function()
    space_indicator.stop()
    hs_mock.uninstall()
  end)

  it("shows one glyph per Space in the menu bar without flashing at start", function()
    space_indicator.start()
    assert.same({ "▧□▧" }, titles)
    assert.equals(0, #flashes)
  end)

  it("flashes one numbered square per Space when the Space changes", function()
    space_indicator.start()
    space_callback()
    assert.same({ "canvas" }, flashes)

    local numbers = {}
    for _, element in ipairs(elements) do
      if element.type == "text" then
        table.insert(numbers, element.text)
      end
    end
    assert.same({ "1", "2", "3" }, numbers)
  end)

  it("replaces a flash that is still showing", function()
    space_indicator.start()
    space_callback()
    space_callback()
    assert.equals(1, canvases_deleted)
  end)

  it("does nothing when rendered before it started", function()
    space_indicator.render(true)
    assert.equals(0, #titles)
    assert.equals(0, #flashes)
  end)

  it("removes the menu bar item on stop", function()
    space_indicator.start()
    space_indicator.stop()
    assert.is_true(deleted)
  end)
end)
