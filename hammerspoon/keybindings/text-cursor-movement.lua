local keybindings = {
  name = "Text Cursor Movement",
  rules = {
    {
      action = "Go to Beginning of Document",
      from = { mods = { "ctrl" }, key = "home" },
      -- to = { mods = { "fn" }, key = "pageup" }, -- weird behavior, the real shortcut is fn + up, but it works
      to = { mods = { "cmd" }, key = "up" }, -- weird behavior, the real shortcut is fn + up, but it works
    },
    {
      action = "Go to End of Document",
      from = { mods = { "ctrl" }, key = "end" },
      -- to = { mods = { "fn" }, key = "pagedown" }, -- weird behavior, the real shortcut is fn + down, but it works
      to = { mods = { "cmd" }, key = "down" }, -- weird behavior, the real shortcut is fn + down, but it works
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
    }
  }
}
return keybindings