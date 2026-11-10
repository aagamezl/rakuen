local fake_window = require("spec.helpers.fake_window")
local window_manager = require("rakuen.core.window_manager")
local window_menu = require("rakuen.ui.window_menu")

describe("window_menu", function()
  local area = { x = 0, y = 25, w = 1440, h = 800 }
  local manager
  local win
  local modal_calls
  local modal

  before_each(function()
    manager = window_manager.new()
    win = fake_window.new({ x = 100, y = 100, w = 500, h = 400 }, fake_window.screen(area))
    modal_calls = {}
    modal = {
      start = function(_, mode)
        table.insert(modal_calls, mode)
      end,
    }
  end)

  it("lists every entry with the chord that does the same", function()
    local choices = window_menu.choices()
    assert.is_true(#choices >= 8)
    for _, choice in ipairs(choices) do
      assert.is_string(choice.text)
      assert.is_string(choice.subText)
      assert.is_string(choice.id)
    end
  end)

  it("has unique ids", function()
    local seen = {}
    for _, choice in ipairs(window_menu.choices()) do
      assert.is_nil(seen[choice.id], choice.id)
      seen[choice.id] = true
    end
  end)

  it("runs a window action by id", function()
    window_menu.run("tile_left", win, manager, modal)
    assert.same({ x = 0, y = 25, w = 720, h = 800 }, win:frame())

    window_menu.run("close", win, manager, modal)
    assert.is_true(win.closed)
  end)

  it("tiles to a quarter", function()
    window_menu.run("tile_top_right", win, manager, modal)
    assert.same({ x = 720, y = 25, w = 720, h = 400 }, win:frame())
  end)

  it("starts the move and resize modes", function()
    window_menu.run("move", win, manager, modal)
    window_menu.run("resize", win, manager, modal)
    assert.same({ "move", "resize" }, modal_calls)
  end)

  it("ignores an unknown id", function()
    assert.equals("unchanged", window_menu.run("nope", win, manager, modal))
  end)
end)
