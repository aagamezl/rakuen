-- Browser Navigation"
local keybindings = {
  name = "Browser Navigation",
  rules = {
    {
      action = "Browser Refresh",
      from = { mods = { "ctrl" }, key = "r" },
      to = { mods = { "cmd" }, key = "r" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      }
    },
    {
      action = "Browser Refresh",
      from = { mods = {}, key = "f5" },
      to = { mods = { "cmd" }, key = "r" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Browser Hard Refresh",
      from = { mods = { "ctrl", "shift" }, key = "r" },
      to = { mods = { "cmd", "shift" }, key = "r" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Browser Hard Refresh",
      from = { mods = { "ctrl", "shift" }, key = "f5" },
      to = { mods = { "cmd", "shift" }, key = "r" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Add Bookmark",
      from = { mods = { "ctrl" }, key = "d" },
      to = { mods = { "cmd" }, key = "d" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Manage Bookmarks",
      from = { mods = { "ctrl", "alt" }, key = "b" },
      to = { mods = { "cmd", "alt" }, key = "b" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Go Back",
      from = { mods = { "alt", "fn" }, key = "left" },
      to = { mods = { "cmd" }, key = "left" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    -- TODO: Add forward navigation
    -- {
    --   action = "Go Forward",
    --   from = { mods = { "alt" }, key = "right" },
    --   to = { mods = { "cmd" }, key = "right" },
    --   only = {
    --     "com.google.Chrome",
    --     "com.apple.Safari",
    --     "com.brave.Browser",
    --     "org.mozilla.firefox"
    --   },
    -- },
    {
      action = "Open Address Bar",
      from = { mods = { "ctrl" }, key = "l" },
      to = { mods = { "cmd" }, key = "l" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "View Source",
      from = { mods = { "ctrl" }, key = "u" },
      to = { mods = { "cmd", "alt" }, key = "u" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Close Tab",
      from = { mods = { "ctrl" }, key = "w" },
      to = { mods = { "cmd" }, key = "w" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Reopen Closed Tab",
      from = { mods = { "ctrl", "shift" }, key = "t" },
      to = { mods = { "cmd", "shift" }, key = "t" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
  },
}

return keybindings
