-- Focus module: GNOME window and application switching.
--
-- Opt acts as GNOME Alt (design decision D1).
-- Cmd+grave and Cmd+Shift+grave are already the native macOS "cycle app
-- windows" chords, so they pass through untouched and need no rule.
-- Cmd+Tab stays the native switcher: Opt+Tab focuses the most recently used
-- window of another app instead of opening a switcher (see docs/feasibility.md).

local window_cycle = require("rakuen.core.window_cycle")

local focus = {}

local FORWARD = window_cycle.FORWARD
local BACKWARD = window_cycle.BACKWARD

local function is_candidate(win)
  return win:isStandard() and win:isVisible() and not win:isMinimized()
end

--- Visible standard windows, front to back, for the current Space.
local function ordered_candidates()
  local succeeded, windows = pcall(hs.window.orderedWindows)
  if not succeeded then
    return {}
  end

  local candidates = {}
  for _, win in ipairs(windows) do
    if is_candidate(win) then
      table.insert(candidates, win)
    end
  end
  return candidates
end

local function app_id(win)
  local app = win:application()
  if app == nil then
    return nil
  end
  return app:bundleID() or app:name()
end

local function focus_window_by_id(candidates, target_id)
  if target_id == nil then
    return
  end

  for _, win in ipairs(candidates) do
    if win:id() == target_id then
      win:focus()
      return
    end
  end
end

--- Cycle through the windows of the focused app, or of every app when `all_apps`.
local function cycle_windows(step, all_apps)
  return function()
    local current = hs.window.focusedWindow()
    local candidates = ordered_candidates()

    local ids = {}
    local current_app = nil
    if current ~= nil then
      current_app = app_id(current)
    end

    local scoped = {}
    for _, win in ipairs(candidates) do
      if all_apps or app_id(win) == current_app then
        table.insert(scoped, win)
        table.insert(ids, win:id())
      end
    end

    local current_id = nil
    if current ~= nil then
      current_id = current:id()
    end

    focus_window_by_id(scoped, window_cycle.next_id(ids, current_id, step))
  end
end

local function switch_application(step)
  return function()
    local candidates = ordered_candidates()

    local entries = {}
    for _, win in ipairs(candidates) do
      table.insert(entries, { app = app_id(win), window = win:id() })
    end

    focus_window_by_id(candidates, window_cycle.app_switch_target(entries, step))
  end
end

local function make_rule(description, from, to, handler, feasibility, note)
  return {
    description = description,
    from = from,
    to = to,
    action = function()
      local succeeded = pcall(handler)
      if not succeeded then
        hs.alert.show("Rakuen: focus action failed")
      end
    end,
    feasibility = feasibility or "yes",
    note = note,
  }
end

local function make_rules()
  return {
    make_rule(
      "Switch applications",
      "Cmd+Tab",
      "Opt+Tab",
      switch_application(FORWARD),
      "partial",
      "Focuses the last used app; no switcher panel. Cmd+Tab stays native"
    ),
    make_rule(
      "Switch applications backward",
      "Cmd+Shift+Tab",
      "Opt+Shift+Tab",
      switch_application(BACKWARD),
      "partial",
      "Focuses the least recently used app"
    ),
    make_rule(
      "Cycle app windows",
      "Cmd+grave",
      "Opt+grave",
      cycle_windows(FORWARD, false),
      "yes",
      "Cmd+grave is already native and passes through"
    ),
    make_rule(
      "Cycle app windows backward",
      "Cmd+Shift+grave",
      "Opt+Shift+grave",
      cycle_windows(BACKWARD, false),
      "yes",
      "Cmd+Shift+grave is already native and passes through"
    ),
    make_rule(
      "Cycle all windows",
      "none",
      "Opt+Escape",
      cycle_windows(FORWARD, true),
      "yes",
      "Visible windows on this Space, in a stable order"
    ),
    make_rule(
      "Cycle all windows backward",
      "none",
      "Opt+Shift+Escape",
      cycle_windows(BACKWARD, true),
      "yes",
      "Visible windows on this Space, in a stable order"
    ),
    make_rule(
      "Cycle group",
      "Cmd+grave",
      "Opt+F6",
      cycle_windows(FORWARD, false),
      "yes",
      "Same per-app cycle as Cycle app windows"
    ),
    make_rule(
      "Cycle group backward",
      "Cmd+Shift+grave",
      "Opt+Shift+F6",
      cycle_windows(BACKWARD, false),
      "yes",
      "Same per-app cycle as Cycle app windows"
    ),
  }
end

focus.rules = make_rules()

return focus
