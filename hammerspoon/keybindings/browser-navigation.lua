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
      from = { mods = { "alt" }, key = "left" },
      to = { mods = { "cmd" }, key = "left" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    -- TODO: Add forward navigation
    {
      action = "Go Forward",
      from = { mods = { "alt" }, key = "right" },
      to = { mods = { "cmd" }, key = "right" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
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
    {
      action = "Select Tab 1",
      from = { mods = { "ctrl" }, key = "1" },
      to = { mods = { "cmd" }, key = "1" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Select Tab 2",
      from = { mods = { "ctrl" }, key = "2" },
      to = { mods = { "cmd" }, key = "2" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Select Tab 3",
      from = { mods = { "ctrl" }, key = "3" },
      to = { mods = { "cmd" }, key = "3" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Select Tab 4",
      from = { mods = { "ctrl" }, key = "4" },
      to = { mods = { "cmd" }, key = "4" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Select Tab 5",
      from = { mods = { "ctrl" }, key = "5" },
      to = { mods = { "cmd" }, key = "5" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Select Tab 6",
      from = { mods = { "ctrl" }, key = "6" },
      to = { mods = { "cmd" }, key = "6" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Select Tab 7",
      from = { mods = { "ctrl" }, key = "7" },
      to = { mods = { "cmd" }, key = "7" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Select Tab 8",
      from = { mods = { "ctrl" }, key = "8" },
      to = { mods = { "cmd" }, key = "8" },
      only = {
        "com.google.Chrome",
        "com.apple.Safari",
        "com.brave.Browser",
        "org.mozilla.firefox"
      },
    },
    {
      action = "Select Last Tab",
      from = { mods = { "ctrl" }, key = "9" },
      to = { mods = { "cmd" }, key = "9" },
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