local apps = require("config.apps")
local rule = require("core.rule")

local terminals = { enable = {}, disable = apps.terminals }
local terminalOnly = { enable = apps.terminals, disable = {} }
local tabApps = { enable = {}, disable = apps.tabApps }
local everyone = { enable = {}, disable = {} }

local function send(mods, key)
  return { mods = mods, key = key }
end

return {
  name = "Editing",
  rules = {
    rule({ description = "Copy", gnome = "Ctrl+C", original = "Cmd+C", mods = { "ctrl" }, key = "c", applications = terminals, action = send({ "cmd" }, "c") }),
    rule({ description = "Copy in terminal", gnome = "Ctrl+Shift+C", original = "Cmd+C", mods = { "ctrl", "shift" }, key = "c", applications = terminalOnly, action = send({ "cmd" }, "c") }),
    rule({ description = "Paste", gnome = "Ctrl+V", original = "Cmd+V", mods = { "ctrl" }, key = "v", applications = terminals, action = send({ "cmd" }, "v") }),
    rule({ description = "Paste in terminal", gnome = "Ctrl+Shift+V", original = "Cmd+V", mods = { "ctrl", "shift" }, key = "v", applications = terminalOnly, action = send({ "cmd" }, "v") }),
    rule({ description = "Cut", gnome = "Ctrl+X", original = "Cmd+X", mods = { "ctrl" }, key = "x", applications = terminals, action = send({ "cmd" }, "x") }),
    rule({ description = "Undo", gnome = "Ctrl+Z", original = "Cmd+Z", mods = { "ctrl" }, key = "z", applications = terminals, action = send({ "cmd" }, "z"), note = "Disabled in terminals because Ctrl+Z suspends a job" }),
    rule({ description = "Redo", gnome = "Ctrl+Y", original = "Cmd+Shift+Z", mods = { "ctrl" }, key = "y", applications = everyone, action = send({ "cmd", "shift" }, "z") }),
    rule({ description = "Redo", gnome = "Ctrl+Shift+Z", original = "Cmd+Shift+Z", mods = { "ctrl", "shift" }, key = "z", applications = everyone, action = send({ "cmd", "shift" }, "z") }),
    rule({ description = "Select all", gnome = "Ctrl+A", original = "Cmd+A", mods = { "ctrl" }, key = "a", applications = terminals, action = send({ "cmd" }, "a") }),
    rule({ description = "Save", gnome = "Ctrl+S", original = "Cmd+S", mods = { "ctrl" }, key = "s", applications = terminals, action = send({ "cmd" }, "s"), note = "Disabled in terminals because Ctrl+S is XOFF" }),
    rule({ description = "Save as", gnome = "Ctrl+Shift+S", original = "Cmd+Shift+S", mods = { "ctrl", "shift" }, key = "s", applications = everyone, action = send({ "cmd", "shift" }, "s") }),
    rule({ description = "Find", gnome = "Ctrl+F", original = "Cmd+F", mods = { "ctrl" }, key = "f", applications = everyone, action = send({ "cmd" }, "f") }),
    rule({ description = "Find next", gnome = "Ctrl+G", original = "Cmd+G", mods = { "ctrl" }, key = "g", applications = everyone, action = send({ "cmd" }, "g") }),
    rule({ description = "New", gnome = "Ctrl+N", original = "Cmd+N", mods = { "ctrl" }, key = "n", applications = everyone, action = send({ "cmd" }, "n") }),
    rule({ description = "Open", gnome = "Ctrl+O", original = "Cmd+O", mods = { "ctrl" }, key = "o", applications = everyone, action = send({ "cmd" }, "o") }),
    rule({ description = "Close window", gnome = "Ctrl+W", original = "Cmd+W", mods = { "ctrl" }, key = "w", applications = terminals, action = send({ "cmd" }, "w") }),
    rule({ description = "Quit", gnome = "Ctrl+Q", original = "Cmd+Q", mods = { "ctrl" }, key = "q", applications = terminals, action = send({ "cmd" }, "q") }),
    rule({ description = "New tab", gnome = "Ctrl+T", original = "Cmd+T", mods = { "ctrl" }, key = "t", applications = everyone, action = send({ "cmd" }, "t") }),
    rule({ description = "Close tab", gnome = "Ctrl+F4", original = "Cmd+W", mods = { "ctrl" }, key = "f4", applications = everyone, action = send({ "cmd" }, "w") }),
    rule({ description = "Next tab", gnome = "Ctrl+Tab", original = "Cmd+Opt+Right", mods = { "ctrl" }, key = "tab", applications = tabApps, action = send({ "cmd", "alt" }, "right"), note = "Disabled where the app already uses Ctrl+Tab" }),
    rule({ description = "Previous tab", gnome = "Ctrl+Shift+Tab", original = "Cmd+Opt+Left", mods = { "ctrl", "shift" }, key = "tab", applications = tabApps, action = send({ "cmd", "alt" }, "left"), note = "Disabled where the app already uses Ctrl+Tab" }),
    rule({ description = "Bold", gnome = "Ctrl+B", original = "Cmd+B", mods = { "ctrl" }, key = "b", applications = everyone, action = send({ "cmd" }, "b") }),
    rule({ description = "Italic", gnome = "Ctrl+I", original = "Cmd+I", mods = { "ctrl" }, key = "i", applications = everyone, action = send({ "cmd" }, "i") }),
    rule({ description = "Underline", gnome = "Ctrl+U", original = "Cmd+U", mods = { "ctrl" }, key = "u", applications = everyone, action = send({ "cmd" }, "u") }),
    rule({ description = "Settings", gnome = "Ctrl+,", original = "Cmd+,", mods = { "ctrl" }, key = ",", applications = everyone, action = send({ "cmd" }, ",") }),
    rule({ description = "Hide app", gnome = "Ctrl+H", original = "Cmd+H", mods = { "ctrl" }, key = "h", applications = terminals, action = send({ "cmd" }, "h") }),
  },
}
