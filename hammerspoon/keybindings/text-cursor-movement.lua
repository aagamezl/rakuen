local keybindings = {
  name = "Text Cursor Movement",
  rules = {
    {
      action = "Go to Beginning of Line",
      from = { mods = { "fn" }, key = "home" },  -- weird behavior, the real shortcut is fn + home, but it works
      to = { mods = { "cmd" }, key = "left" },
      synthetic = true,
    },
    {
      action = "Go to End of Line",
      from = { mods = { "fn" }, key = "end" },  -- weird behavior, the real shortcut is fn + end, but it works
      to = { mods = { "cmd" }, key = "right" },
      synthetic = true,
    },
    {
      action = "Go to Beginning of Document",
      from = { mods = { "ctrl" }, key = "home" },
      to = { mods = { "cmd" }, key = "up" },
      synthetic = true,
    },
    {
      action = "Go to End of Document",
      from = { mods = { "ctrl" }, key = "end" },
      to = { mods = { "cmd" }, key = "down" },
      synthetic = true,
    },
    {
      action = "Move One Word To The Left",
      from = { mods = { "ctrl" }, key = "left" },
      to = { mods = { "alt" }, key = "left" },
    },
    {
      action = "Move One Word To The Right",
      from = { mods = { "ctrl" }, key = "right" },
      to = { mods = { "alt" }, key = "right" },
    },
    {
      action = "Go Back",
      from = { mods = { "alt" }, key = "left" },
      to = { mods = { "ctrl" }, key = "-" },
      only = {
        "com.exafunction.windsurf",
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92"
      },
    },
    {
      action = "Go Forward",
      from = { mods = { "alt" }, key = "right" },
      to = { mods = { "ctrl", "shift" }, key = "-" },
      only = {
        "com.exafunction.windsurf",
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92"
      },
    }
  }
}

return keybindings