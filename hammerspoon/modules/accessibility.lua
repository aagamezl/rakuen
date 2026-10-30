local binder = require("core.binder")
local rule = require("core.rule")

local everyone = { enable = {}, disable = {} }

local function toggleVoiceOver()
  binder.fire({ "cmd" }, "f5")
end

return {
  name = "Accessibility",
  rules = {
    rule({ description = "Zoom toggle", gnome = "Alt+Super+8", original = "Opt+Cmd+8", mods = { "alt", "cmd" }, key = "8", applications = everyone, action = "passthrough", note = "Native macOS Zoom shortcut" }),
    rule({ description = "Zoom in", gnome = "Alt+Super+=", original = "Opt+Cmd+=", mods = { "alt", "cmd" }, key = "=", applications = everyone, action = "passthrough", note = "Native macOS Zoom shortcut" }),
    rule({ description = "Zoom out", gnome = "Alt+Super+-", original = "Opt+Cmd+-", mods = { "alt", "cmd" }, key = "-", applications = everyone, action = "passthrough", note = "Native macOS Zoom shortcut" }),
    rule({ description = "Screen reader", gnome = "Alt+Super+S", original = "Cmd+F5", mods = { "alt", "cmd" }, key = "s", applications = everyone, action = toggleVoiceOver, note = "Toggles VoiceOver. VoiceOver must already be installed" }),
  },
}
