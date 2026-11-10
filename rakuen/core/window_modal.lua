-- Keyboard move and resize of the focused window (GNOME Alt+F7 / Alt+F8).
--
-- While active, a temporary eventtap swallows every key: arrows change the
-- window, Return keeps it, Escape puts it back. A timeout ends the mode so a
-- forgotten modal can never keep swallowing the keyboard.
-- `step` is pure and tested; `start` and `stop` use `hs`.

local frame_math = require("rakuen.core.frame_math")

local window_modal = {}

window_modal.STEP = 20
window_modal.BIG_STEP = 100
window_modal.MIN_SIZE = { w = 200, h = 120 }
window_modal.VISIBLE_MARGIN = 80
window_modal.TIMEOUT_SECONDS = 30

local ARROW_DELTAS = {
  left = { x = -1, y = 0 },
  right = { x = 1, y = 0 },
  up = { x = 0, y = -1 },
  down = { x = 0, y = 1 },
}

local ACCEPT_KEYS = { ["return"] = true, padenter = true }

--- Apply one key press. Returns { status = "continue" | "accept" | "cancel", frame }.
--- `mode` is "move" or "resize"; `shift` makes the step bigger; `area` is the screen frame.
function window_modal.step(mode, frame, original, key, shift, area)
  assert(mode == "move" or mode == "resize", "mode must be 'move' or 'resize'")

  if key == "escape" then
    return { status = "cancel", frame = original }
  end

  if ACCEPT_KEYS[key] then
    return { status = "accept", frame = frame }
  end

  local direction = ARROW_DELTAS[key]
  if direction == nil then
    return { status = "continue", frame = frame }
  end

  local size = window_modal.STEP
  if shift then
    size = window_modal.BIG_STEP
  end

  local delta_x = direction.x * size
  local delta_y = direction.y * size

  if mode == "move" then
    local moved = frame_math.shift(frame, delta_x, delta_y)
    return {
      status = "continue",
      frame = frame_math.keep_visible(moved, area, window_modal.VISIBLE_MARGIN),
    }
  end

  return {
    status = "continue",
    frame = frame_math.resize(frame, delta_x, delta_y, window_modal.MIN_SIZE),
  }
end

local active = nil

--- End the modal, if one is running.
function window_modal.stop()
  if active == nil then
    return
  end

  active.tap:stop()
  active.timer:stop()
  active = nil
end

local function handle_key(session, event)
  local key = hs.keycodes.map[event:getKeyCode()]
  local shift = event:getFlags().shift == true
  local area = session.win:screen():frame()

  local previous = session.frame
  local result = window_modal.step(session.mode, previous, session.original, key, shift, area)
  session.frame = result.frame

  if result.frame ~= previous then
    session.win:setFrame(result.frame, 0)
  end

  if result.status ~= "continue" then
    window_modal.stop()
  end
end

--- Start moving ("move") or resizing ("resize") `win` with the arrow keys.
function window_modal.start(win, mode)
  assert(mode == "move" or mode == "resize", "mode must be 'move' or 'resize'")
  window_modal.stop()

  local session = { win = win, mode = mode, original = win:frame(), frame = win:frame() }

  local tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local succeeded = pcall(handle_key, session, event)
    if not succeeded then
      window_modal.stop()
    end
    return true
  end)

  local timer = hs.timer.doAfter(window_modal.TIMEOUT_SECONDS, window_modal.stop)

  active = { tap = tap, timer = timer }
  tap:start()
  hs.alert.show("Arrows to change, Return to keep, Escape to cancel")
end

return window_modal
