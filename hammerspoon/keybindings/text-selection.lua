local keybindings = {
  {
    action = "Select one word to the left",
    from = { mods = { "ctrl", "shift" }, key = "left" },
    to = { mods = { "alt", "shift" }, key = "left" },
  },
  {
    action = "Select one word to the right",
    from = { mods = { "ctrl", "shift" }, key = "right" },
    to = { mods = { "alt", "shift" }, key = "right" },
  },
  {
    action = "Select to beginning of line",
    from = { mods = { "shift" }, key = "home" },
    to = { mods = { "cmd", "shift" }, key = "left" },
  },
  {
    action = "Select to end of line",
    from = { mods = { "shift" }, key = "end" },
    to = { mods = { "cmd", "shift" }, key = "right" },
  },
}

return keybindings