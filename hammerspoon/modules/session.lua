local apps = require("config.apps")
local rule = require("core.rule")

local everyone = { enable = {}, disable = {} }
local browsers = { enable = apps.browsers, disable = {} }

local function lockScreen()
  hs.caffeinate.lockScreen()
end

local function logOut()
  hs.timer.doAfter(0, function()
    local result = hs.dialog.blockAlert("Log out", "Log out of this Mac?", "Log Out", "Cancel")

    if result == "Log Out" then
      hs.osascript.applescript('tell application "System Events" to log out')
    end
  end)
end

return {
  name = "Session",
  rules = {
    rule({
      description = "Lock",
      gnome = "Super+L",
      original = "Cmd+Ctrl+Q",
      mods = { "cmd" },
      key = "l",
      applications = everyone,
      action = lockScreen,
    }),
    rule({
      description = "Focus location bar",
      gnome = "Ctrl+L",
      original = "Cmd+L",
      mods = { "ctrl" },
      key = "l",
      applications = browsers,
      action = { mods = { "cmd" }, key = "l" },
      note = "Browsers only, because Cmd+L locks the screen",
    }),
    rule({
      description = "Log out",
      gnome = "Ctrl+Alt+Delete",
      original = "Cmd+Shift+Q",
      mods = { "ctrl", "alt" },
      key = "forwarddelete",
      applications = everyone,
      action = logOut,
      note = "Confirms, then asks loginwindow to log out",
    }),
  },
}
