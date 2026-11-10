local fake_window = require("spec.helpers.fake_window")
local frame_math = require("rakuen.core.frame_math")
local window_manager = require("rakuen.core.window_manager")

describe("window_manager", function()
  local area = { x = 0, y = 25, w = 1440, h = 800 }
  local start = { x = 200, y = 100, w = 600, h = 400 }
  local manager
  local screen
  local win

  before_each(function()
    manager = window_manager.new()
    screen = fake_window.screen(area)
    win = fake_window.new(start, screen)
  end)

  describe("toggle_maximize", function()
    it("fills the usable area, below the menu bar", function()
      assert.equals("done", manager:toggle_maximize(win))
      assert.same(area, win:frame())
    end)

    it("restores the saved frame on the second press", function()
      manager:toggle_maximize(win)
      assert.equals("done", manager:toggle_maximize(win))
      assert.same(start, win:frame())
    end)

    it("restores to the original frame after maximize, tile, then toggle", function()
      manager:toggle_maximize(win)
      manager:tile(win, "left")
      manager:tile(win, "left")
      assert.same(start, win:frame())
    end)

    it("works on the display the window is on", function()
      local second = fake_window.screen({ x = 1440, y = 25, w = 1920, h = 1055 })
      local other = fake_window.new(start, second)
      manager:toggle_maximize(other)
      assert.same({ x = 1440, y = 25, w = 1920, h = 1055 }, other:frame())
    end)
  end)

  describe("tile_step with up and down", function()
    it("maximizes on up and restores on down", function()
      assert.equals("done", manager:tile_step(win, "up"))
      assert.same(area, win:frame())
      assert.equals("done", manager:tile_step(win, "down"))
      assert.same(start, win:frame())
    end)

    it("up twice stays maximized", function()
      manager:tile_step(win, "up")
      assert.equals("unchanged", manager:tile_step(win, "up"))
      assert.same(area, win:frame())
    end)

    it("down does nothing for a window Rakuen did not move", function()
      assert.equals("unchanged", manager:tile_step(win, "down"))
      assert.same(start, win:frame())
      assert.equals(0, win.set_frame_calls)
    end)

    it("unmaximize does nothing after the user moved the window", function()
      manager:tile_step(win, "up")
      win:setFrame({ x = 50, y = 50, w = 700, h = 500 })
      assert.equals("unchanged", manager:unmaximize(win))
      assert.same({ x = 50, y = 50, w = 700, h = 500 }, win:frame())
    end)

    it("unmaximize restores the frame from before", function()
      manager:tile_step(win, "up")
      assert.equals("done", manager:unmaximize(win))
      assert.same(start, win:frame())
    end)
  end)

  describe("quarter tiling", function()
    local top_left = { x = 0, y = 25, w = 720, h = 400 }
    local top_right = { x = 720, y = 25, w = 720, h = 400 }
    local bottom_left = { x = 0, y = 425, w = 720, h = 400 }
    local bottom_right = { x = 720, y = 425, w = 720, h = 400 }

    it("left then up gives the top-left quarter", function()
      manager:tile_step(win, "left")
      manager:tile_step(win, "up")
      assert.same(top_left, win:frame())
    end)

    it("right then down gives the bottom-right quarter", function()
      manager:tile_step(win, "right")
      manager:tile_step(win, "down")
      assert.same(bottom_right, win:frame())
    end)

    it("moves along a row between quarters", function()
      manager:tile_step(win, "left")
      manager:tile_step(win, "down")
      manager:tile_step(win, "right")
      assert.same(bottom_right, win:frame())
    end)

    it("goes from a quarter back to the half, then to the original frame", function()
      manager:tile_step(win, "left")
      manager:tile_step(win, "up")
      manager:tile_step(win, "down")
      assert.same({ x = 0, y = 25, w = 720, h = 800 }, win:frame())
      manager:tile_step(win, "left")
      assert.same(start, win:frame())
    end)

    it("up from a top quarter maximizes", function()
      manager:tile_step(win, "right")
      manager:tile_step(win, "up")
      assert.same(top_right, win:frame())
      manager:tile_step(win, "up")
      assert.same(area, win:frame())
    end)

    it("restores the original frame from a quarter", function()
      manager:tile_step(win, "left")
      manager:tile_step(win, "up")
      manager:tile_step(win, "left")
      assert.same(start, win:frame())
    end)

    it("tile_to goes straight to a quarter and back", function()
      assert.equals("done", manager:tile_to(win, "bottom_left"))
      assert.same(bottom_left, win:frame())
      manager:tile_to(win, "bottom_left")
      assert.same(start, win:frame())
    end)

    it("keeps working when the app refuses part of the size", function()
      local wide = { x = 200, y = 100, w = 1000, h = 400 }
      local stubborn = fake_window.new(wide, screen, { min_w = 900 })
      manager:tile_step(stubborn, "left")
      assert.equals("partial", manager:tile_step(stubborn, "up"))
      manager:tile_step(stubborn, "left")
      assert.same(wide, stubborn:frame())
    end)

    it("skips fullscreen windows", function()
      local fullscreen = fake_window.new(area, screen, { fullscreen = true })
      assert.equals("unsupported", manager:tile_step(fullscreen, "up"))
    end)
  end)

  describe("tile", function()
    it("tiles to the left half and back", function()
      assert.equals("done", manager:tile(win, "left"))
      assert.same({ x = 0, y = 25, w = 720, h = 800 }, win:frame())
      manager:tile(win, "left")
      assert.same(start, win:frame())
    end)

    it("tiles to the right half", function()
      manager:tile(win, "right")
      assert.same({ x = 720, y = 25, w = 720, h = 800 }, win:frame())
    end)

    it("moves from the left half to the right half without losing the original", function()
      manager:tile(win, "left")
      manager:tile(win, "right")
      manager:tile(win, "right")
      assert.same(start, win:frame())
    end)

    it("reports a partial result when the app refuses the size", function()
      local stubborn = fake_window.new(start, screen, { min_w = 900 })
      assert.equals("partial", manager:tile(stubborn, "left"))
    end)

    it("still toggles back when the app refused the size", function()
      local wide = { x = 200, y = 100, w = 1000, h = 400 }
      local stubborn = fake_window.new(wide, screen, { min_w = 900 })
      manager:tile(stubborn, "left")
      assert.equals(900, stubborn:frame().w)
      manager:tile(stubborn, "left")
      assert.same(wide, stubborn:frame())
    end)

    it("rejects an unknown side", function()
      assert.has_error(function()
        manager:tile(win, "middle")
      end)
    end)
  end)

  describe("unsupported windows", function()
    it("skips fullscreen windows", function()
      local fullscreen = fake_window.new(area, screen, { fullscreen = true })
      assert.equals("unsupported", manager:toggle_maximize(fullscreen))
      assert.equals("unsupported", manager:tile(fullscreen, "left"))
      assert.equals("unsupported", manager:move_to_display(fullscreen, "left"))
      assert.equals(0, fullscreen.set_frame_calls)
    end)

    it("skips non-standard windows such as dialogs", function()
      local dialog = fake_window.new(start, screen, { standard = false })
      assert.equals("unsupported", manager:tile_step(dialog, "up"))
      assert.equals(0, dialog.set_frame_calls)
    end)
  end)

  describe("move_to_display", function()
    it("moves to the neighbor display", function()
      local right_screen = fake_window.screen({ x = 1440, y = 25, w = 1920, h = 1055 })
      local left_screen = fake_window.screen(area, { right = right_screen })
      local moving = fake_window.new(start, left_screen)

      assert.equals("done", manager:move_to_display(moving, "right"))
      assert.equals(right_screen, moving:screen())
    end)

    it("does nothing when there is no display in that direction", function()
      assert.equals("unchanged", manager:move_to_display(win, "up"))
      assert.equals(screen, win:screen())
    end)

    describe("with a maximized or tiled window", function()
      local small_area = area
      local big_area = { x = 1440, y = 25, w = 2880, h = 1575 }
      local big_screen
      local small_screen
      local moving

      before_each(function()
        big_screen = fake_window.screen(big_area, { left = nil })
        small_screen = fake_window.screen(small_area, { right = big_screen })
        big_screen.neighbors.left = small_screen
        moving = fake_window.new(start, small_screen)
      end)

      it("stays maximized on the bigger display", function()
        manager:tile_step(moving, "up")
        assert.equals("done", manager:move_to_display(moving, "right"))
        assert.equals(big_screen, moving:screen())
        assert.same(big_area, moving:frame())
      end)

      it("stays maximized when moving back to the smaller display", function()
        manager:tile_step(moving, "up")
        manager:move_to_display(moving, "right")
        manager:move_to_display(moving, "left")
        assert.same(small_area, moving:frame())
      end)

      it("keeps a half tile on the new display", function()
        manager:tile_step(moving, "left")
        manager:move_to_display(moving, "right")
        assert.same({ x = 1440, y = 25, w = 1440, h = 1575 }, moving:frame())
      end)

      it("keeps a quarter tile on the new display", function()
        manager:tile_step(moving, "right")
        manager:tile_step(moving, "down")
        manager:move_to_display(moving, "right")
        local expected = { x = 2880, y = 812, w = 1440, h = 788 }
        assert.is_true(math.abs(moving:frame().x - expected.x) <= 8)
        assert.is_true(math.abs(moving:frame().y - expected.y) <= 8)
        assert.is_true(math.abs(moving:frame().w - expected.w) <= 8)
      end)

      it("restores to a scaled version of the original frame", function()
        manager:tile_step(moving, "up")
        manager:move_to_display(moving, "right")
        assert.equals("done", manager:tile_step(moving, "down"))

        local restored = moving:frame()
        assert.is_true(restored.x >= big_area.x)
        assert.is_true(restored.x + restored.w <= big_area.x + big_area.w)
        assert.is_true(restored.w > start.w)
      end)

      it("leaves a free window as it is", function()
        manager:move_to_display(moving, "right")
        assert.is_false(frame_math.same_frame(moving:frame(), big_area))
        assert.equals("unchanged", manager:unmaximize(moving))
      end)

      it("keeps a window that was tiled by hand", function()
        local by_hand = fake_window.new({ x = 0, y = 25, w = 720, h = 800 }, small_screen)
        manager:move_to_display(by_hand, "right")
        assert.same({ x = 1440, y = 25, w = 1440, h = 1575 }, by_hand:frame())
      end)
    end)

    it("rejects an unknown direction", function()
      assert.has_error(function()
        manager:move_to_display(win, "sideways")
      end)
    end)
  end)

  describe("close and minimize", function()
    it("closes the window", function()
      assert.equals("done", manager:close(win))
      assert.is_true(win.closed)
    end)

    it("minimizes the window", function()
      assert.equals("done", manager:minimize(win))
      assert.is_true(win.minimized)
    end)
  end)
end)
