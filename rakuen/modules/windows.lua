-- Windows module: GNOME window management (maximize, tile, move, close, ...).
--
-- Chords use Cmd as the GNOME Super key and Opt as Alt (design decision D1).
-- Rules run in every application. The logic lives in rakuen.core.window_manager,
-- window_modal and rakuen.ui.window_menu; this file only maps chords to them.
-- Synthetic Cmd+Up/Down from the text navigation module carry the Rakuen marker,
-- so they never reach these rules (task 5.7).

local window_manager = require("rakuen.core.window_manager")
local window_menu = require("rakuen.ui.window_menu")
local window_modal = require("rakuen.core.window_modal")

local windows = {}

local manager = window_manager.new()

-- Alerts for statuses the user should know about. "done" and "unchanged" stay silent.
local STATUS_MESSAGES = {
  unsupported = "This window cannot be moved or resized",
  partial = "The app limits this window's size",
}

local function focused_window()
  local succeeded, win = pcall(hs.window.focusedWindow)
  if not succeeded then
    return nil
  end
  return win
end

--- Wrap `handler(win)` so it runs on the focused window and never raises.
local function on_focused_window(handler)
  return function()
    local win = focused_window()
    if win == nil then
      return
    end

    local succeeded, status = pcall(handler, win)
    if not succeeded then
      hs.alert.show("Rakuen: window action failed")
      return
    end

    if STATUS_MESSAGES[status] ~= nil then
      hs.alert.show(STATUS_MESSAGES[status])
    end
  end
end

local function make_rule(description, from, to, handler, feasibility, note)
  return {
    description = description,
    from = from,
    to = to,
    action = on_focused_window(handler),
    feasibility = feasibility or "yes",
    note = note,
  }
end

local function display_rule(direction, note)
  local name = direction:sub(1, 1):upper() .. direction:sub(2)
  return make_rule(
    "Move to display " .. direction,
    "none",
    "Cmd+Shift+" .. name,
    function(win)
      return manager:move_to_display(win, direction)
    end,
    "yes",
    note
  )
end

local function maximize(win)
  return manager:maximize(win)
end

local function unmaximize(win)
  return manager:unmaximize(win)
end

local function make_rules()
  return {
    make_rule("Close", "Cmd+W", "Opt+F4", function(win)
      return manager:close(win)
    end, "yes", "Apps that quit on the last window still quit"),
    make_rule("Toggle maximize", "none", "Opt+F10", function(win)
      return manager:toggle_maximize(win)
    end, "yes", "Fills the screen and restores the saved frame. Not a fullscreen Space"),
    make_rule("Maximize", "none", "Cmd+Up", maximize),
    make_rule("Unmaximize", "none", "Cmd+Down", unmaximize),
    make_rule("Unmaximize (F5)", "none", "Opt+F5", unmaximize),
    make_rule("Tile left", "none", "Cmd+Left", function(win)
      return manager:tile(win, "left")
    end, "yes", "Left half; press again to restore"),
    make_rule("Tile right", "none", "Cmd+Right", function(win)
      return manager:tile(win, "right")
    end, "yes", "Right half; press again to restore"),
    make_rule("Minimize", "Cmd+M", "Cmd+H", function(win)
      return manager:minimize(win)
    end, "yes", "Overrides Hide. Hide moves to Ctrl+H"),
    display_rule("left"),
    display_rule("right"),
    display_rule("up", "No-op when displays are side by side"),
    display_rule("down", "No-op when displays are side by side"),
    make_rule("Begin move", "none", "Opt+F7", function(win)
      window_modal.start(win, "move")
    end, "yes", "Arrows move; Shift for bigger steps; Return keeps; Escape cancels"),
    make_rule("Begin resize", "none", "Opt+F8", function(win)
      window_modal.start(win, "resize")
    end, "yes", "Arrows resize from the bottom-right; Return keeps; Escape cancels"),
    make_rule("Window action menu", "none", "Opt+Space", function(win)
      window_menu.show(win, manager, window_modal)
    end, "partial", "Chooser for close, minimize, maximize, tile, move, resize and displays"),
  }
end

windows.rules = make_rules()
windows.manager = manager

return windows
