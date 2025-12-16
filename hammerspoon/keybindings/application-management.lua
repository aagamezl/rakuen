local keybindings = {
  {
    action = "New Window",
    from = { mods = { "ctrl" }, key = "n" },
    to = { mods = { "cmd" }, key = "n" },
  },
  {
    action = "New Tab",
    from = { mods = { "ctrl" }, key = "t" },
    to = { mods = { "cmd" }, key = "t" },
  },
  {
    action = "Close Window",
    from = { mods = { "alt" }, key = "f4" },
    to = { mods = { "cmd" }, key = "w" },
  },
  {
    action = "Cycle Next Open Apps",
    from = { mods = { "alt" }, key = "tab" },
    to = { mods = { "cmd" }, key = "tab" },
  },
  {
    action = "Cycle Previous Open Apps",
    from = { mods = { "alt", "shift" }, key = "tab" },
    to = { mods = { "cmd", "shift" }, key = "tab" },
  },
}

return keybindings
