-- Browser Navigation
local appGroups = require("utils/app-groups")

local browsers = appGroups.browsers

local keybindings = {
  name = "Browser Navigation",
  rules = {
    {
      action = "Browser Refresh",
      from = { mods = { "ctrl" }, key = "r" },
      to = { mods = { "cmd" }, key = "r" },
      only = browsers,
    },
    {
      action = "Browser Refresh",
      from = { mods = {}, key = "f5" },
      to = { mods = { "cmd" }, key = "r" },
      only = browsers,
    },
    {
      action = "Browser Hard Refresh",
      from = { mods = { "ctrl", "shift" }, key = "r" },
      to = { mods = { "cmd", "shift" }, key = "r" },
      only = browsers,
    },
    {
      action = "Browser Hard Refresh",
      from = { mods = { "ctrl", "shift" }, key = "f5" },
      to = { mods = { "cmd", "shift" }, key = "r" },
      only = browsers,
    },
    {
      action = "Add Bookmark",
      from = { mods = { "ctrl" }, key = "d" },
      to = { mods = { "cmd" }, key = "d" },
      only = browsers,
    },
    {
      action = "Manage Bookmarks",
      from = { mods = { "ctrl", "alt" }, key = "b" },
      to = { mods = { "cmd", "alt" }, key = "b" },
      only = browsers,
    },
    {
      action = "Go Back",
      from = { mods = { "alt" }, key = "left" },
      to = { mods = { "cmd" }, key = "[" },
      only = browsers,
    },
    {
      action = "Go Forward",
      from = { mods = { "alt" }, key = "right" },
      to = { mods = { "cmd" }, key = "]" },
      only = browsers,
    },
    {
      action = "Open Address Bar",
      from = { mods = { "ctrl" }, key = "l" },
      to = { mods = { "cmd" }, key = "l" },
      only = browsers,
    },
    {
      action = "View Source",
      from = { mods = { "ctrl" }, key = "u" },
      to = { mods = { "cmd", "alt" }, key = "u" },
      only = browsers,
    },
    {
      action = "Reopen Closed Tab",
      from = { mods = { "ctrl", "shift" }, key = "t" },
      to = { mods = { "cmd", "shift" }, key = "t" },
      only = browsers,
    },
    {
      action = "Select Tab 1",
      from = { mods = { "ctrl" }, key = "1" },
      to = { mods = { "cmd" }, key = "1" },
      only = browsers,
    },
    {
      action = "Select Tab 2",
      from = { mods = { "ctrl" }, key = "2" },
      to = { mods = { "cmd" }, key = "2" },
      only = browsers,
    },
    {
      action = "Select Tab 3",
      from = { mods = { "ctrl" }, key = "3" },
      to = { mods = { "cmd" }, key = "3" },
      only = browsers,
    },
    {
      action = "Select Tab 4",
      from = { mods = { "ctrl" }, key = "4" },
      to = { mods = { "cmd" }, key = "4" },
      only = browsers,
    },
    {
      action = "Select Tab 5",
      from = { mods = { "ctrl" }, key = "5" },
      to = { mods = { "cmd" }, key = "5" },
      only = browsers,
    },
    {
      action = "Select Tab 6",
      from = { mods = { "ctrl" }, key = "6" },
      to = { mods = { "cmd" }, key = "6" },
      only = browsers,
    },
    {
      action = "Select Tab 7",
      from = { mods = { "ctrl" }, key = "7" },
      to = { mods = { "cmd" }, key = "7" },
      only = browsers,
    },
    {
      action = "Select Tab 8",
      from = { mods = { "ctrl" }, key = "8" },
      to = { mods = { "cmd" }, key = "8" },
      only = browsers,
    },
    {
      action = "Select Last Tab",
      from = { mods = { "ctrl" }, key = "9" },
      to = { mods = { "cmd" }, key = "9" },
      only = browsers,
    },
  },
}

return keybindings
