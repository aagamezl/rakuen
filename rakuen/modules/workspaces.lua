-- Workspaces module: GNOME workspace switching on macOS Spaces.
--
-- Spaces are a horizontal list and must already exist (no vertical workspaces).
-- Ctrl+Cmd+Left/Right are native macOS chords after bin/install.sh moved them
-- (D7), so they pass through and need no rule. Ctrl+Cmd+Up/Down open Mission
-- Control and Application windows natively.
-- Insert/Remove space add or delete a Space on the current display, and the
-- indicator (rakuen/ui/space_indicator.lua) shows where you are.
-- Previous/next space are left to macOS. First and last space repeat the
-- Ctrl+Cmd+Left/Right chord. The Space actions live in
-- rakuen/core/space_actions.lua.

local rule = require("rakuen.core.rule").new
local shortcut_check = require("rakuen.core.shortcut_check")
local space_actions = require("rakuen.core.space_actions")
local space_indicator = require("rakuen.ui.space_indicator")

local workspaces = {}

--- Run a handler without letting an error (missing hs.spaces, no screen) escape.
local function guarded(handler)
  return function()
    local succeeded = pcall(handler)
    if not succeeded then
      hs.alert.show("Rakuen: Spaces are not available")
    end
  end
end

local function make_rules()
  local rules = {
    rule(
      "First space",
      "none",
      "Cmd+Home",
      guarded(space_actions.go_to("first")),
      "Repeats Ctrl+Cmd+Left until the first Space"
    ),
    rule(
      "Last space",
      "none",
      "Cmd+End",
      guarded(space_actions.go_to("last")),
      "Repeats Ctrl+Cmd+Right until the last Space"
    ),
  }

  table.insert(
    rules,
    rule(
      "Insert space",
      "none",
      "Ctrl+Cmd+=",
      guarded(space_actions.insert_space),
      "Opens Mission Control to add a Space at the end of the display"
    )
  )
  table.insert(
    rules,
    rule(
      "Remove space",
      "none",
      "Ctrl+Cmd+-",
      guarded(space_actions.remove_space),
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
        rule(description, "none", chord, guarded(space_actions.move_window_to(which)), move_note)
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
