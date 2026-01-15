local keybindings = {
  name = "Application Management",
  rules = {
    {
      action = "New Window",
      from = { mods = { "ctrl" }, key = "n" },
      to = { mods = { "cmd" }, key = "n" },
    },
    {
      action = "New Tab",
      from = { mods = { "ctrl" }, key = "t" },
      to = { mods = { "cmd" }, key = "t" },
    },
    {
      action = "Close Window",
      from = { mods = { "alt" }, key = "f4" },
      to = { mods = { "cmd" }, key = "w" },
    },
    {
      action = "Cycle Next Open Apps",
      from = { mods = { "alt" }, key = "tab" },
      to = { mods = { "cmd" }, key = "tab" },
      stateful = true,
      -- to = {
      --   handler = function()
      --     print("Cycle Next Open Apps")
      --     -- hs.window.switcher.nextWindow()


      --     -- hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, true):post()
      --     -- hs.eventtap.event.newKeyEvent(hs.keycodes.map.tab, true):post()

      --     -- hs.eventtap.event.newKeyEvent(hs.keycodes.map.tab, false):post()
      --     -- hs.eventtap.event.newKeyEvent(hs.keycodes.map.cmd, false):post()
      --     local evDown = hs.eventtap.event.newKeyEvent({"cmd"}, "tab", true)
      --     evDown:setProperty(hs.eventtap.event.properties.keyboardEventAutorepeat, 1)
      --     evDown:post()

      --     local evUp = hs.eventtap.event.newKeyEvent({"cmd"}, "tab", false)
      --     evUp:setProperty(hs.eventtap.event.properties.keyboardEventAutorepeat, 1)
      --     evUp:post()
      --   end
      -- }
    },
    {
      action = "Cycle Previous Open Apps",
      from = { mods = { "alt", "shift" }, key = "tab" },
      to = { mods = { "cmd", "shift" }, key = "tab" },
      stateful = true,
      -- to = {
      --   handler = function()
      --     print("Cycle Previous Open Apps")
      --     hs.window.switcher.previousWindow()
      --   end
      -- }
    },
  },
}

-- hs.window.switcher.ui.showSelectedThumbnail = true
-- hs.window.switcher.ui.showTitles = true
-- hs.window.switcher.ui.showThumbnails = false
-- hs.window.switcher.ui.showSelectedTitle = false

-- hs.window.switcher.ui.textColor = {0.9,0.9,0.9}
-- hs.window.switcher.ui.fontName = 'Lucida Grande'
-- hs.window.switcher.ui.textSize = 24
-- hs.window.switcher.ui.highlightColor = {0.8,0.5,0,0.2}
-- hs.window.switcher.ui.backgroundColor = {0.3,0.3,0.3,0.8}
-- hs.window.switcher.ui.onlyActiveApplication = false
-- hs.window.switcher.ui.showTitles = true
-- hs.window.switcher.ui.titleBackgroundColor = {0,0,0}
-- hs.window.switcher.ui.showThumbnails = false
-- hs.window.switcher.ui.thumbnailSize = 128
-- hs.window.switcher.ui.showSelectedThumbnail = false
-- hs.window.switcher.ui.selectedThumbnailSize = 384
-- hs.window.switcher.ui.showSelectedTitle = true

-- Modern, sleek window switcher UI design
hs.window.switcher.ui.textColor = { 0.92, 0.92, 0.92, 1 }
hs.window.switcher.ui.fontName = 'Helvetica Neue Light'
hs.window.switcher.ui.fontSize = 20
hs.window.switcher.ui.highlightColor = { 0.9, 0.4, 0.1, 0.3 } -- Warm amber accent
hs.window.switcher.ui.backgroundColor = { 0.05, 0.05, 0.08, 0.7 }
hs.window.switcher.ui.titleBackgroundColor = { 0, 0, 0, 0.8 }
hs.window.switcher.ui.showThumbnails = false
hs.window.switcher.ui.thumbnailSize = 128
hs.window.switcher.ui.showSelectedThumbnail = false
hs.window.switcher.ui.selectedThumbnailSize = 320

print(hs.inspect(hs.window.switcher.ui))

return keybindings