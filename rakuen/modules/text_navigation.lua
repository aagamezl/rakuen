-- Text navigation module: Linux caret keys (Home, End, Ctrl+Arrows, ...).
--
-- Each rule listens for the GTK chord and posts the macOS chord that does the same.
-- Rules run only while the focused element is a text field (D5). Outside text
-- fields the keys pass through, so Spaces and Mission Control keep working.
-- Posted chords carry the Rakuen marker, so the windows module never sees the
-- synthetic Cmd+Up/Down sent for Ctrl+Home/End.

local text_gate = require("rakuen.core.text_gate")

local text_navigation = {}

local TERMINALS = {
  "com.apple.Terminal",
  "com.googlecode.iterm2",
  "com.github.wez.wezterm",
  "net.kovidgoyal.kitty",
  "org.alacritty",
  "com.mitchellh.ghostty",
}

-- Apps that expose no focused AX element (spike 1.7). The gate always passes for them.
local FORCE = {
  "com.google.Chrome",
  "com.microsoft.VSCode",
  "com.microsoft.VSCodeInsiders",
  "com.tinyspeck.slackmacgap",
}

--- Gate used by every rule: true when the caret is in a text field.
local function in_text_field(bundle_id)
  return text_gate.allows(text_gate.focused_role(), bundle_id, FORCE)
end

local function make_rule(description, from, to, action_mods, key, note)
  return {
    description = description,
    from = from,
    to = to,
    applications = { disable = TERMINALS },
    when = in_text_field,
    action = { mods = action_mods, key = key },
    feasibility = "yes",
    note = note,
  }
end

local function make_rules()
  return {
    make_rule("Start of line", "Cmd+Left", "Home", { "cmd" }, "left"),
    make_rule("End of line", "Cmd+Right", "End", { "cmd" }, "right"),
    make_rule(
      "Select to start of line",
      "Cmd+Shift+Left",
      "Shift+Home",
      { "cmd", "shift" },
      "left"
    ),
    make_rule("Select to end of line", "Cmd+Shift+Right", "Shift+End", { "cmd", "shift" }, "right"),

    make_rule("Start of document", "Cmd+Up", "Ctrl+Home", { "cmd" }, "up"),
    make_rule("End of document", "Cmd+Down", "Ctrl+End", { "cmd" }, "down"),
    make_rule(
      "Select to start of document",
      "Cmd+Shift+Up",
      "Ctrl+Shift+Home",
      { "cmd", "shift" },
      "up"
    ),
    make_rule(
      "Select to end of document",
      "Cmd+Shift+Down",
      "Ctrl+Shift+End",
      { "cmd", "shift" },
      "down"
    ),

    make_rule("Previous word", "Opt+Left", "Ctrl+Left", { "alt" }, "left"),
    make_rule("Next word", "Opt+Right", "Ctrl+Right", { "alt" }, "right"),
    make_rule(
      "Select previous word",
      "Opt+Shift+Left",
      "Ctrl+Shift+Left",
      { "alt", "shift" },
      "left"
    ),
    make_rule(
      "Select next word",
      "Opt+Shift+Right",
      "Ctrl+Shift+Right",
      { "alt", "shift" },
      "right"
    ),

    make_rule("Previous paragraph", "Opt+Up", "Ctrl+Up", { "alt" }, "up"),
    make_rule("Next paragraph", "Opt+Down", "Ctrl+Down", { "alt" }, "down"),
    make_rule(
      "Select to previous paragraph",
      "Opt+Shift+Up",
      "Ctrl+Shift+Up",
      { "alt", "shift" },
      "up"
    ),
    make_rule(
      "Select to next paragraph",
      "Opt+Shift+Down",
      "Ctrl+Shift+Down",
      { "alt", "shift" },
      "down"
    ),

    make_rule("Delete previous word", "Opt+Delete", "Ctrl+Backspace", { "alt" }, "delete"),
    make_rule("Delete next word", "Opt+Fn+Delete", "Ctrl+Del", { "alt" }, "forwarddelete"),
  }
end

text_navigation.rules = make_rules()
text_navigation.terminals = TERMINALS
text_navigation.force = FORCE

return text_navigation
