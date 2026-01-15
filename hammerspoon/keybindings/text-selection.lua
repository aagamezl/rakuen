local keybindings = {
  name = "Text Selection",
  rules = {
    {
      action = "Select one word to the left",
      from = { mods = { "ctrl", "shift" }, key = "left" },
      to = { mods = { "alt", "shift" }, key = "left" },
    },
    {
      action = "Select to end of line",
      from = { mods = { "shift" }, key = "end" },
      to = { mods = { "cmd", "shift" }, key = "right" },
    },
    {
      action = "Select to Beginning of Document ",
      from = { mods = { "ctrl", "shift" }, key = "home" },
      to = { mods = { "cmd", "shift" }, key = "up" },
    },
    {
      action = "Select To End of Document",
      from = { mods = { "ctrl", "shift" }, key = "end" },
      to = { mods = { "cmd", "shift" }, key = "down" },
    },
  },
}

return keybindings

-- Danica Pension
