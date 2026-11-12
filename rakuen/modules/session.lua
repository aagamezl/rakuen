-- Session module: lock, log out, shut down and accessibility.
--
-- Cmd acts as GNOME Super (design decision D1). Shut down asks first, because
-- it loses unsaved work. Log out relies on the macOS confirmation. Handlers run
-- outside the event tap (rakuen/core/deferred.lua) since a modal dialog would
-- otherwise block it.
-- Zoom (Opt+Cmd+8, Opt+Cmd+=, Opt+Cmd+-) is native macOS, so it has no rule.

local deferred = require("rakuen.core.deferred")

local session = {}

-- Browsers focus the location bar with Cmd+L, which Lock now owns, so they
-- keep GNOME's Ctrl+L through a rule that posts Cmd+L for them only.
local BROWSERS = {
  "com.apple.Safari",
  "com.google.Chrome",
  "org.mozilla.firefox",
  "com.brave.Browser",
  "com.microsoft.edgemac",
  "company.thebrowser.Browser",
}

--- Ask the user to confirm; true only when they pick the action button.
local function confirm(message, detail, action_label)
  local answer = hs.dialog.blockAlert(message, detail, action_label, "Cancel")
  return answer == action_label
end

local function lock_screen()
  hs.caffeinate.lockScreen()
end

local function log_out()
  -- macOS shows its own confirmation, so Rakuen adds none.
  hs.caffeinate.logOut()
end

local function shut_down()
  if confirm("Shut down?", "Unsaved work in open apps may be lost.", "Shut Down") then
    hs.caffeinate.shutdownSystem()
  end
end

local function rule(description, from, to, action, feasibility, note, applications)
  return {
    description = description,
    from = from,
    to = to,
    action = action,
    feasibility = feasibility,
    note = note,
    applications = applications,
  }
end

session.rules = {
  rule(
    "Lock",
    "Cmd+Ctrl+Q",
    "Cmd+L",
    deferred.guard(lock_screen),
    "yes",
    "hs.caffeinate.lockScreen. Browsers keep Ctrl+L for the location bar"
  ),
  rule(
    "Focus location bar",
    "Cmd+L",
    "Ctrl+L",
    { mods = { "cmd" }, key = "l" },
    "yes",
    "Browsers only: Cmd+L is Lock, so Ctrl+L posts Cmd+L for them",
    { enable = BROWSERS }
  ),
  rule(
    "Log out",
    "Cmd+Shift+Q",
    "Cmd+Opt+L",
    deferred.guard(log_out),
    "yes",
    "macOS asks for confirmation, then logs out"
  ),
  rule(
    "Shut down",
    "none",
    "Cmd+Opt+F4",
    deferred.guard(shut_down),
    "yes",
    "Confirms first, then shuts down"
  ),
  rule(
    "Screen reader",
    "Cmd+F5",
    "Opt+Cmd+S",
    { mods = { "cmd" }, key = "f5" },
    "partial",
    "Toggles VoiceOver by posting its Cmd+F5 shortcut"
  ),
}

return session
