<<<<<<< HEAD
-- luacheck: ignore 212
=======
>>>>>>> 669e447 (feat: text navigation module complete)
-- Fake Hammerspoon windows and screens for unit tests.
--
-- A fake window keeps its frame in memory. Options let a test mimic windows
-- that refuse a size, fullscreen windows and dialogs.

local fake_window = {}

local next_id = 1

--- Create a fake screen. `area` is its usable frame. Neighbors are set with `neighbors`.
function fake_window.screen(area, neighbors)
  local screen = { neighbors = neighbors or {} }

  function screen:frame()
    return area
  end

  function screen:toWest()
    return self.neighbors.left
  end

  function screen:toEast()
    return self.neighbors.right
  end

  function screen:toNorth()
    return self.neighbors.up
  end

  function screen:toSouth()
    return self.neighbors.down
  end

  return screen
end

--- Create a fake window. options: fullscreen, standard (default true),
--- min_w and min_h (smallest size the "app" accepts).
function fake_window.new(frame, screen, options)
  local settings = options or {}
  local win = {
    current = { x = frame.x, y = frame.y, w = frame.w, h = frame.h },
    on_screen = screen,
    window_id = next_id,
    closed = false,
    minimized = false,
    set_frame_calls = 0,
  }
  next_id = next_id + 1

  function win:id()
    return self.window_id
  end

  function win:frame()
    return { x = self.current.x, y = self.current.y, w = self.current.w, h = self.current.h }
  end

  function win:setFrame(new_frame)
    self.set_frame_calls = self.set_frame_calls + 1
    self.current = {
      x = new_frame.x,
      y = new_frame.y,
      w = math.max(new_frame.w, settings.min_w or 0),
      h = math.max(new_frame.h, settings.min_h or 0),
    }
  end

  function win:screen()
    return self.on_screen
  end

  function win:isFullscreen()
    return settings.fullscreen == true
  end

  function win:isStandard()
    return settings.standard ~= false
  end

  function win:close()
    self.closed = true
  end

  function win:minimize()
    self.minimized = true
  end

  function win:moveToScreen(target)
    self.on_screen = target
    local area = target:frame()
    self.current = { x = area.x + 10, y = area.y + 10, w = self.current.w, h = self.current.h }
  end

  return win
end

return fake_window
