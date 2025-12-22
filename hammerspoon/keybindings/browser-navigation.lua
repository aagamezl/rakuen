-- Browser Navigation"
local keybindings = {
  {
    action = "Browser Refresh",
    from = { mods = { "ctrl" }, key = "r" },
    to = { mods = { "cmd" }, key = "r" },
    except = {
      "com.apple.Terminal",
      "com.googlecode.iterm2",
      "co.realize.kitty",
      "com.exafunction.windsurf",
      "com.microsoft.VSCode",
    },
  },
  {
    action = "Browser Hard Refresh",
    from = { mods = { "ctrl", "shift" }, key = "r" },
    to = { mods = { "cmd", "shift" }, key = "r" },
  },
  {
    action = "Go Back",
    from = { mods = { "option" }, key = "left_arrow" },
    to = { mods = { "cmd" }, key = "open_bracket" },
  },
  {
    action = "Go Forward",
    from = { mods = { "option" }, key = "right_arrow" },
    to = { mods = { "cmd" }, key = "close_bracket" },
  },
  {
    action = "Open Address Bar",
    from = { mods = { "ctrl" }, key = "l" },
    to = { mods = { "cmd" }, key = "l" },
  },
  {
    action = "Add Bookmark",
    from = { mods = { "ctrl", "shift" }, key = "d" },
    to = { mods = { "cmd", "shift" }, key = "d" },
  },
  -- {
  --   action = "View Source",
  --   from = { mods = { "ctrl" }, key = "u" },
  --   to = { mods = { "cmd" }, key = "u" },
  -- },
  {
    action = "Manage Bookmarks",
    from = { mods = { "ctrl", "shift" }, key = "b" },
    to = { mods = { "cmd", "option" }, key = "b" },
  },
}

return keybindings