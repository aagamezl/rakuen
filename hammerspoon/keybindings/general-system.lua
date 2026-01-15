local keybindings = {
  name = "General System",
  rules = {
    {
      action = "Lock Screen",
      from = { mods = { "ctrl", "alt" }, key = "l" },
      to = { mods = { "cmd", "ctrl" }, key = "q" },
    },
    {
      action = "Open Activity Monitor",
      from = { mods = { "ctrl", "shift" }, key = "escape" },
      to = { app = "Activity Monitor" },
    },
    {
      action = "Show Desktop",
      from = { mods = { "ctrl", "cmd" }, key = "d" },
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
      action = "Show Dock",
      from = { mods = { "ctrl", "alt" }, key = "d" },
      to = { mods = { "cmd", "alt" }, key = "d" },
    },
    {
      action = "Logout User",
      from = { mods = { "ctrl", "alt" }, key = "forwarddelete" },
      to = { mods = { "cmd", "shift" }, key = "q" },
    },
    -- {
    --   action = "Shutdown System",
    --   from = { mods = { "ctrl", "alt" }, key = "s" },
    --   to = { mods = { "ctrl", "alt" }, key = "q" },
    -- },
    {
      action = "Reload Hammerspoon Config",
      from = { mods = { "ctrl", "cmd" }, key = "r" },
      to = {
        handler = function()
          hs.alert.show("Config loaded")

          hs.reload()
        end
      }
    },
  }
}

return keybindings
