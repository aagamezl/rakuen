local keybindings = {
  {
    action = "Lock Screen",
    from = { mods = { "ctrl" }, key = "l" },
    to = { mods = { "cmd" }, key = "l" },
  },
  {
    action = "Open Task Manager",
    from = { mods = { "ctrl", "shift" }, key = "l" },
    to = { mods = { "cmd", "shift" }, key = "l" },
  },
  {
    action = "Open Activity Monitor",
    from = { mods = { "ctrl", "shift" }, key = "escape" },
    to = { app = "Activity Monitor" },
  },
  {
    action = "Show Desktop",
    from = { mods = { "cmd" }, key = "d" },
    to = { mods = { "fn" }, key = "f11" },
  },
  {
    action = "Open Finder",
    from = { mods = { "cmd" }, key = "e" },
    to = { mods = { "cmd", "option" }, key = "space" },
  },
  {
    action = "Open Terminal",
    from = { mods = { "ctrl", "alt" }, key = "t" },
    to = { app = "iTerm" },
  },
  {
    action = "Rename Object",
    from = { mods = {}, key = "f2" },
    to = { mods = {}, key = "return" },
  },
  {
    action = "Show Hidden Files",
    from = { mods = { "cmd" }, key = "h" },
    to = { mods = { "cmd", "shift" }, key = "." },
  },
  {
    action = "Reload Hammerspoon Config",
    from = { mods = { "cmd", "ctrl" }, key = "r" },
    to = {
      handler = function()
        hs.alert.show("Config loaded")

        hs.reload()
      end
    },
  },
}

return keybindings
