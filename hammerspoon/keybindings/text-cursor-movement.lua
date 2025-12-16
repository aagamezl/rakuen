local keybindings = {
  {
    action = "Go to Beginning of Line",
    from = { mods = { "home" } },
    to = { mods = { "cmd" }, key = "left" },
  },
  {
    action = "Go to End of Line",
    from = { mods = { "end" } },
    to = { mods = { "cmd" }, key = "right" },
  },
  {
    action = "Go to Beginning of Document",
    from = { mods = { "ctrl" }, key = "home" },
    to = { mods = { "cmd" }, key = "up" },
  },
  {
    action = "Go to End of Document",
    from = { mods = { "ctrl" }, key = "end" },
    to = { mods = { "cmd" }, key = "down" },
  },
  -- {
  --   action = "Move one word to the left",
  --   from = { mods = { "ctrl" }, key = "left" },
  --   to = { mods = { "alt" }, key = "left" },
  -- },
  -- {
  --   action = "Move one word to the right",
  --   from = { mods = { "ctrl" }, key = "right" },
  --   to = { mods = { "alt" }, key = "right" },
  -- },
}

return keybindings