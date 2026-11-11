-- Workspaces module: GNOME workspace switching on macOS Spaces.
--
-- Spaces are a horizontal list and must already exist (no vertical workspaces).
-- Ctrl+Cmd+Left/Right are native macOS chords after bin/install.sh moved them
-- (D7), so they pass through and need no rule. Ctrl+Cmd+Up/Down open Mission
-- Control and Application windows natively.
-- Insert/Remove space add or delete a Space on the current display, and the
-- indicator (rakuen/ui/space_indicator.lua) shows where you are.
-- Previous/next space are left to macOS. First and last space repeat the
-- Ctrl+Cmd+Left/Right chord. hs.spaces.moveWindowToSpace no longer works on
-- recent macOS, so a window is moved by grabbing its title bar, switching
-- Space with the chord while the mouse is held, then releasing (best-effort).

local mission_control = require("rakuen.core.mission_control")
local shortcut_check = require("rakuen.core.shortcut_check")
local space_indicator = require("rakuen.ui.space_indicator")
local space_nav = require("rakuen.core.space_nav")
local synthetic = require("rakuen.core.synthetic")

local workspaces = {}

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

local function main_screen_spaces()
  local screen = hs.screen.mainScreen()
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

--- Add a Space at the end of the current display.
local function insert_space()
  when_modifiers_released(function()
    mission_control.add_space(function(succeeded, message)
      if not succeeded then
        hs.alert.show("Rakuen: could not add a Space: " .. tostring(message))
        return
      end
      space_indicator.render(true)
    end)
  end)
end

--- Poll until the active Space is no longer `previous_id`, then call
--- `callback(true)`; `callback(false)` if it never changes. The switch
--- animation takes a variable time, so a fixed wait is not reliable.
local function wait_until_left(previous_id, callback, waited)
  waited = waited or 0
  local _, now_id = main_screen_spaces()
  if now_id ~= previous_id then
    callback(true)
    return
  end
  if waited >= LEAVE_TIMEOUT then
    callback(false)
    return
  end

  hs.timer.doAfter(LEAVE_POLL, function()
    wait_until_left(previous_id, callback, waited + LEAVE_POLL)
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

--- Remove the current Space. macOS cannot remove the Space being shown, so
--- switch to a neighbor first, wait until that has happened and the animation
--- has settled, then remove the old one through Mission Control.
--- Windows on the removed Space move to a neighbor, as in Mission Control.
local function remove_space()
  local ids, current_id = main_screen_spaces()
  local direction = space_nav.removal_direction(ids, current_id)
  if direction == nil then
    hs.alert.show("Rakuen: cannot remove the only Space")
    return
  end

  local screen = hs.screen.mainScreen()
  local index = space_nav.index_of(ids, current_id)

  press_space_chord(direction, 1, 0)
  wait_until_left(
    current_id,
    alert_on_error(function(left)
      if not left then
        hs.alert.show("Rakuen: could not leave the Space, so it was not removed")
        return
      end

      hs.timer.doAfter(
        SWITCH_SETTLE,
        alert_on_error(function()
          when_modifiers_released(alert_on_error(function()
            mission_control.remove_space(screen:id(), index, function(succeeded, message)
              if not succeeded then
                hs.alert.show("Rakuen: could not remove the Space: " .. tostring(message))
                return
              end
              space_indicator.render(true)
            end)
          end))
        end)
      )
    end)
  )
end

local function go_to(which)
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

--- Hold the window by the top-left corner of its title bar, switch Space,
--- then let go and put the window back where it was (the drag nudged it).
--- The corner is used because the middle of a title bar often holds tabs,
--- a search field or toolbar buttons that cannot be dragged.
local function move_window_to(which)
  return function()
    if move_in_progress then
      return
    end

    local win = hs.window.focusedWindow()
    if win == nil or is_finder_desktop(win) then
      return
    end

    local ids, current_id = main_screen_spaces()
    local plan = space_nav.plan(ids, current_id, which)
    if plan == nil then
      hs.alert.show("No Space to move this window to")
      return
    end

    -- Guard against overlapping moves; reset by a timer if a step fails.
    move_in_progress = true
    move_token = move_token + 1
    local token = move_token
    hs.timer.doAfter(MOVE_TIMEOUT, function()
      if token == move_token then
        move_in_progress = false
      end
    end)

    win:unminimize()
    win:raise()

    local original_frame = win:frame()
    local original_mouse = hs.mouse.absolutePosition()
    local grab = space_nav.title_bar_point(original_frame)
    local nudge = space_nav.drag_point(grab)

    -- Each step waits a moment so macOS registers the one before it.
    hs.mouse.absolutePosition(grab)
    hs.timer.doAfter(MOUSE_DOWN_DELAY, function()
      post_mouse(hs.eventtap.event.types.leftMouseDown, grab)
    end)
    hs.timer.doAfter(DRAG_DELAY, function()
      post_mouse(hs.eventtap.event.types.leftMouseDragged, nudge, space_nav.DRAG_NUDGE)
    end)

    local release_delay = press_space_chord(plan.direction, plan.count, CHORD_DELAY)
    hs.timer.doAfter(release_delay + RELEASE_DELAY, function()
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
    end)
  end
end

--- Run a handler without letting an error (missing hs.spaces, no screen) escape.
local function guarded(handler)
  return function()
    local succeeded = pcall(handler)
    if not succeeded then
      hs.alert.show("Rakuen: Spaces are not available")
    end
  end
end

local function rule(description, from, to, action, feasibility, note)
  return {
    description = description,
    from = from,
    to = to,
    action = action,
    feasibility = feasibility,
    note = note,
  }
end

local function make_rules()
  local rules = {
    rule(
      "First space",
      "none",
      "Cmd+Home",
      guarded(go_to("first")),
      "partial",
      "Repeats Ctrl+Cmd+Left until the first Space"
    ),
    rule(
      "Last space",
      "none",
      "Cmd+End",
      guarded(go_to("last")),
      "partial",
      "Repeats Ctrl+Cmd+Right until the last Space"
    ),
  }

  table.insert(
    rules,
    rule(
      "Insert space",
      "none",
      "Ctrl+Cmd+=",
      guarded(insert_space),
      "partial",
      "Adds a Space at the end of the display"
    )
  )
  table.insert(
    rules,
    rule(
      "Remove space",
      "none",
      "Ctrl+Cmd+-",
      guarded(remove_space),
      "partial",
      "Switches to a neighbor Space, then removes the old one. Its windows move to a neighbor"
    )
  )

  local move_note = "Best-effort: drags the title bar while switching Space"
  local moves = {
    { "previous", { "Cmd+Shift+PageUp", "Cmd+Shift+Opt+Left", "Ctrl+Shift+Opt+Left" } },
    { "next", { "Cmd+Shift+PageDown", "Cmd+Shift+Opt+Right", "Ctrl+Shift+Opt+Right" } },
    { "first", { "Cmd+Shift+Home" } },
    { "last", { "Cmd+Shift+End" } },
  }
  for _, move in ipairs(moves) do
    local which, chords = move[1], move[2]
    for index, chord in ipairs(chords) do
      local description = "Move window to " .. which .. " space"
      if index > 1 then
        description = description .. " (" .. chord .. ")"
      end
      table.insert(
        rules,
        rule(description, "none", chord, guarded(move_window_to(which)), "partial", move_note)
      )
    end
  end

  return rules
end

--- Startup: warn when the installer has not moved the shortcuts (task 8.1),
--- and show the workspace indicator.
function workspaces.on_load(logger)
  shortcut_check.check(logger)
  space_indicator.start()
end

workspaces.rules = make_rules()

return workspaces
