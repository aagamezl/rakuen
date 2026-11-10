local apps = require("config.apps")
local rule = require("core.rule")

local textApps = { enable = {}, disable = apps.terminals }

local function caret(description, gnome, original, mods, key, toMods, toKey)
  return rule({
    description = description,
    gnome = gnome,
    original = original,
    mods = mods,
    key = key,
    applications = textApps,
    whenText = true,
    action = { mods = toMods, key = toKey },
    note = "Only while a text field is focused. Disabled in terminals",
  })
end

return {
  name = "Text navigation",
  rules = {
    caret("Start of line", "Home", "Cmd+Left", {}, "home", { "cmd" }, "left"),
    caret("End of line", "End", "Cmd+Right", {}, "end", { "cmd" }, "right"),
    caret("Start of document", "Ctrl+Home", "Cmd+Up", { "ctrl" }, "home", { "cmd" }, "up"),
    caret("End of document", "Ctrl+End", "Cmd+Down", { "ctrl" }, "end", { "cmd" }, "down"),
    caret("Previous word", "Ctrl+Left", "Opt+Left", { "ctrl" }, "left", { "alt" }, "left"),
    caret("Next word", "Ctrl+Right", "Opt+Right", { "ctrl" }, "right", { "alt" }, "right"),
    caret("Previous paragraph", "Ctrl+Up", "Opt+Up", { "ctrl" }, "up", { "alt" }, "up"),
    caret("Next paragraph", "Ctrl+Down", "Opt+Down", { "ctrl" }, "down", { "alt" }, "down"),
    caret("Select to start of line", "Shift+Home", "Shift+Cmd+Left", { "shift" }, "home", { "shift", "cmd" }, "left"),
    caret("Select to end of line", "Shift+End", "Shift+Cmd+Right", { "shift" }, "end", { "shift", "cmd" }, "right"),
    caret("Select previous word", "Ctrl+Shift+Left", "Shift+Opt+Left", { "ctrl", "shift" }, "left", { "shift", "alt" }, "left"),
    caret("Select next word", "Ctrl+Shift+Right", "Shift+Opt+Right", { "ctrl", "shift" }, "right", { "shift", "alt" }, "right"),
    caret("Select to start of document", "Ctrl+Shift+Home", "Shift+Cmd+Up", { "ctrl", "shift" }, "home", { "shift", "cmd" }, "up"),
    caret("Select to end of document", "Ctrl+Shift+End", "Shift+Cmd+Down", { "ctrl", "shift" }, "end", { "shift", "cmd" }, "down"),
    caret("Delete previous word", "Ctrl+Backspace", "Opt+Delete", { "ctrl" }, "delete", { "alt" }, "delete"),
    caret("Delete next word", "Ctrl+ForwardDelete", "Opt+ForwardDelete", { "ctrl" }, "forwarddelete", { "alt" }, "forwarddelete"),
  },
}
