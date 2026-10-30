local rule = require("core.rule")
local spaces = require("core.spaces")

local everyone = { enable = {}, disable = {} }
local SPACE_HOPS = 16

local function pressSpace(key, times)
  spaces.move(key, times)
end

local function previousSpace()
  pressSpace("left", 1)
end

local function nextSpace()
  pressSpace("right", 1)
end

local function firstSpace()
  -- Control+Left stops on the first Space when the shortcut does not wrap.
  pressSpace("left", SPACE_HOPS)
end

local function lastSpace()
  pressSpace("right", SPACE_HOPS)
end

local function moveWindow()
  hs.alert.show("macOS does not let Rakuen move this window to another Space")
end

return {
  name = "Workspaces",
  rules = {
    rule({ description = "Previous space", gnome = "Super+PageUp", original = "Ctrl+Left", mods = { "cmd" }, key = "pageup", applications = everyone, action = previousSpace }),
    rule({ description = "Previous space", gnome = "Super+Ctrl+Left", original = "Ctrl+Left", mods = { "cmd", "ctrl" }, key = "left", applications = everyone, action = previousSpace }),
    rule({ description = "Next space", gnome = "Super+PageDown", original = "Ctrl+Right", mods = { "cmd" }, key = "pagedown", applications = everyone, action = nextSpace }),
    rule({ description = "Next space", gnome = "Super+Ctrl+Right", original = "Ctrl+Right", mods = { "cmd", "ctrl" }, key = "right", applications = everyone, action = nextSpace }),
    rule({ description = "First space", gnome = "Super+Home", original = "none", mods = { "cmd" }, key = "home", applications = everyone, action = firstSpace, note = "Moves left until the first existing Space" }),
    rule({ description = "Last space", gnome = "Super+End", original = "none", mods = { "cmd" }, key = "end", applications = everyone, action = lastSpace, note = "Moves right until the last existing Space" }),
    rule({ description = "Move window to previous Space", gnome = "Super+Shift+PageUp", original = "none", mods = { "cmd", "shift" }, key = "pageup", applications = everyone, action = moveWindow, note = "Best-effort; Spaces cannot always accept a moved window" }),
    rule({ description = "Move window to previous Space", gnome = "Super+Shift+Alt+Left", original = "none", mods = { "cmd", "shift", "alt" }, key = "left", applications = everyone, action = moveWindow, note = "Best-effort; Spaces cannot always accept a moved window" }),
    rule({ description = "Move window to previous Space", gnome = "Ctrl+Shift+Alt+Left", original = "none", mods = { "ctrl", "shift", "alt" }, key = "left", applications = everyone, action = moveWindow, note = "Best-effort; Spaces cannot always accept a moved window" }),
    rule({ description = "Move window to next Space", gnome = "Super+Shift+PageDown", original = "none", mods = { "cmd", "shift" }, key = "pagedown", applications = everyone, action = moveWindow, note = "Best-effort; Spaces cannot always accept a moved window" }),
    rule({ description = "Move window to next Space", gnome = "Super+Shift+Alt+Right", original = "none", mods = { "cmd", "shift", "alt" }, key = "right", applications = everyone, action = moveWindow, note = "Best-effort; Spaces cannot always accept a moved window" }),
    rule({ description = "Move window to next Space", gnome = "Ctrl+Shift+Alt+Right", original = "none", mods = { "ctrl", "shift", "alt" }, key = "right", applications = everyone, action = moveWindow, note = "Best-effort; Spaces cannot always accept a moved window" }),
    rule({ description = "Move window to first Space", gnome = "Super+Shift+Home", original = "none", mods = { "cmd", "shift" }, key = "home", applications = everyone, action = moveWindow, note = "Best-effort; Spaces cannot always accept a moved window" }),
    rule({ description = "Move window to last Space", gnome = "Super+Shift+End", original = "none", mods = { "cmd", "shift" }, key = "end", applications = everyone, action = moveWindow, note = "Best-effort; Spaces cannot always accept a moved window" }),
  },
}
