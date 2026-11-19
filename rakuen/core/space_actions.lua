-- Space actions: go to a Space, add or remove one, and move a window to one.
--
-- These drive macOS Spaces through synthetic keys, mouse events and Mission
-- Control, because the hs.spaces calls that do this no longer work on recent
-- macOS. Which Space to go to is decided by rakuen/core/space_nav.lua (pure).
-- A window is moved by grabbing its title bar, switching Space with the
-- Ctrl+Cmd+Left/Right chord while the mouse is held, then releasing (best-effort).

local mission_control = require("rakuen.core.mission_control")
local screens = require("rakuen.core.screens")
local space_indicator = require("rakuen.ui.space_indicator")
local space_nav = require("rakuen.core.space_nav")
local synthetic = require("rakuen.core.synthetic")

local space_actions = {}

-- Seconds between repeated presses, so the Space animation does not drop one.
local STEP_DELAY = 0.4
-- Seconds between the mouse steps of a window move (press, drag, switch, release).
local MOUSE_DOWN_DELAY = 0.02
local DRAG_DELAY = 0.05
local CHORD_DELAY = 0.1
local RELEASE_DELAY = 0.3
local RESTORE_DELAY = 0.01
-- Removing a Space: poll for the switch away from it, then let the animation
-- finish before opening Mission Control.
local LEAVE_POLL = 0.1
local LEAVE_TIMEOUT = 3.0
local SWITCH_SETTLE = 0.6
-- How long to wait for the shortcut's modifier keys to be released.
local MODIFIER_POLL = 0.05
local MODIFIER_TIMEOUT = 2.0
-- Give up on a move that never finishes, so the next one is not blocked.
local MOVE_TIMEOUT = 3.0

local move_in_progress = false
local move_token = 0

--- Spaces and the active Space of `screen`, or of the current display.
local function main_screen_spaces(screen)
  screen = screen or screens.current()
  local ids = hs.spaces.spacesForScreen(screen)
  local current_id = hs.spaces.activeSpaceOnScreen(screen)
  return ids, current_id
end

--- Post Ctrl+Cmd+Left/Right once. Arrow keys carry the fn flag on a real
--- keyboard, and macOS ignores the Space shortcut without it.
local function post_space_chord(direction)
  synthetic.post_key({ "ctrl", "cmd", "fn" }, direction)
end

--- Post the chord `count` times from `start_delay`, spaced so each one lands.
--- Returns the delay after the last press.
local function press_space_chord(direction, count, start_delay)
  for step = 1, count do
    hs.timer.doAfter(start_delay + (step - 1) * STEP_DELAY, function()
      post_space_chord(direction)
    end)
  end

  return start_delay + count * STEP_DELAY
end

local function post_mouse(event_type, point, delta_x)
  local event = hs.eventtap.event.newMouseEvent(event_type, point)
  if delta_x ~= nil then
    event:setProperty(hs.eventtap.event.properties.mouseEventDeltaX, delta_x)
  end

  event:setProperty(hs.eventtap.event.properties.eventSourceUserData, synthetic.MARKER)
  event:post()
end

--- Run `callback` once Ctrl/Cmd/Opt/Shift are all released. Mission Control
--- misbehaves when it is driven while the chord that started it is still held.
local function when_modifiers_released(callback, waited)
  waited = waited or 0

  local held = hs.eventtap.checkKeyboardModifiers()
  local is_held = held.ctrl or held.cmd or held.alt or held.shift
  if not is_held or waited >= MODIFIER_TIMEOUT then
    callback()
    return
  end

  hs.timer.doAfter(MODIFIER_POLL, function()
    when_modifiers_released(callback, waited + MODIFIER_POLL)
  end)
end

--- Run a timer callback, alerting instead of failing silently in the console.
local function alert_on_error(callback)
  return function(...)
    local succeeded, callback_error = pcall(callback, ...)
    if not succeeded then
      hs.alert.show("Rakuen: " .. tostring(callback_error))
    end
  end
end

--- A Mission Control callback: alert on failure, refresh the indicator on success.
--- `failure_label` completes "Rakuen: could not ...".
local function report_result(failure_label)
  return function(succeeded, message)
    if not succeeded then
      hs.alert.show("Rakuen: could not " .. failure_label .. ": " .. tostring(message))
      return
    end

    space_indicator.render(true)
  end
end

--- Poll until the active Space is no longer `previous_id`, then call
--- `callback(true)`; `callback(false)` if it never changes. The switch
--- animation takes a variable time, so a fixed wait is not reliable.
local function wait_until_left(screen, previous_id, callback, waited)
  waited = waited or 0

  local _, now_id = main_screen_spaces(screen)
  if now_id ~= previous_id then
    callback(true)
    return
  end

  if waited >= LEAVE_TIMEOUT then
    callback(false)
    return
  end

  hs.timer.doAfter(LEAVE_POLL, function()
    wait_until_left(screen, previous_id, callback, waited + LEAVE_POLL)
  end)
end

--- Add a Space at the end of the current display.
function space_actions.insert_space()
  when_modifiers_released(function()
    mission_control.add_space(screens.current():id(), report_result("add a Space"))
  end)
end

--- Open Mission Control and remove the Space at `index`, once the chord is released.
local function remove_through_mission_control(screen, index)
  when_modifiers_released(alert_on_error(function()
    mission_control.remove_space(screen:id(), index, report_result("remove the Space"))
  end))
end

--- Remove the current Space. macOS cannot remove the Space being shown, so
--- switch to a neighbor first, wait until that has happened and the animation
--- has settled, then remove the old one through Mission Control.
--- Windows on the removed Space move to a neighbor, as in Mission Control.
function space_actions.remove_space()
  local screen = screens.current()
  local ids, current_id = main_screen_spaces(screen)

  local direction = space_nav.removal_direction(ids, current_id)
  if direction == nil then
    hs.alert.show("Rakuen: cannot remove the only Space")
    return
  end

  local index = space_nav.index_of(ids, current_id)

  press_space_chord(direction, 1, 0)
  wait_until_left(
    screen,
    current_id,
    alert_on_error(function(left)
      if not left then
        hs.alert.show("Rakuen: could not leave the Space, so it was not removed")
        return
      end

      hs.timer.doAfter(
        SWITCH_SETTLE,
        alert_on_error(function()
          remove_through_mission_control(screen, index)
        end)
      )
    end)
  )
end

--- A handler that switches to the `which` Space ("first", "last", ...).
function space_actions.go_to(which)
  return function()
    local ids, current_id = main_screen_spaces()
    local plan = space_nav.plan(ids, current_id, which)
    if plan == nil then
      return
    end

    press_space_chord(plan.direction, plan.count, 0)
  end
end

--- True for the Finder desktop pseudo-window, which is bigger than the screen
--- and cannot be moved to another Space.
local function is_finder_desktop(win)
  local app = win:application()
  if app == nil or app:bundleID() ~= "com.apple.finder" then
    return false
  end

  local screen_frame = win:screen():frame()
  local frame = win:frame()
  return frame.w > screen_frame.w and frame.h > screen_frame.h
end

--- Mark a move as running, and clear the mark by timer if a step never finishes.
local function begin_move()
  move_in_progress = true
  move_token = move_token + 1

  local token = move_token
  hs.timer.doAfter(MOVE_TIMEOUT, function()
    if token == move_token then
      move_in_progress = false
    end
  end)
end

--- Press on `grab` and drag a little to `nudge`. Each step waits a moment so
--- macOS registers the one before it.
local function hold_window(grab, nudge)
  hs.mouse.absolutePosition(grab)

  hs.timer.doAfter(MOUSE_DOWN_DELAY, function()
    post_mouse(hs.eventtap.event.types.leftMouseDown, grab)
  end)

  hs.timer.doAfter(DRAG_DELAY, function()
    post_mouse(hs.eventtap.event.types.leftMouseDragged, nudge, space_nav.DRAG_NUDGE)
  end)
end

--- Let go at `nudge`, then put the window and the mouse back where they were.
local function release_window(win, nudge, original_frame, original_mouse)
  post_mouse(hs.eventtap.event.types.leftMouseUp, nudge)

  hs.timer.doAfter(RESTORE_DELAY, function()
    if win:isVisible() then
      win:setFrame(original_frame, 0)
    end

    win:raise()
    win:focus()
    hs.mouse.absolutePosition(original_mouse)
    move_in_progress = false
  end)
end

--- A handler that moves the focused window to the `which` Space.
--- Hold the window by the top-left corner of its title bar, switch Space,
--- then let go and put the window back where it was (the drag nudged it).
--- The corner is used because the middle of a title bar often holds tabs,
--- a search field or toolbar buttons that cannot be dragged.
function space_actions.move_window_to(which)
  return function()
    if move_in_progress then
      return
    end

    local win = hs.window.focusedWindow()
    if win == nil or is_finder_desktop(win) then
      return
    end

    local ids, current_id = main_screen_spaces(win:screen())
    local plan = space_nav.plan(ids, current_id, which)
    if plan == nil then
      hs.alert.show("No Space to move this window to")
      return
    end

    begin_move()

    win:unminimize()
    win:raise()

    local original_frame = win:frame()
    local original_mouse = hs.mouse.absolutePosition()
    local grab = space_nav.title_bar_point(original_frame)
    local nudge = space_nav.drag_point(grab)

    hold_window(grab, nudge)

    local release_delay = press_space_chord(plan.direction, plan.count, CHORD_DELAY)
    hs.timer.doAfter(release_delay + RELEASE_DELAY, function()
      release_window(win, nudge, original_frame, original_mouse)
    end)
  end
end

return space_actions
