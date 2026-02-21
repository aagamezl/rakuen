local keyEventListener = require("keybindings/utils/key-event-listener")
local logger = require("utils/logger")

local SHUTDOWN_DELAY = 10

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
    {
      action = "Shutdown System",
      from = { mods = { "ctrl", "alt" }, key = "s" },
      to = {
        handler = function()
          local result = hs.dialog.blockAlert(
            "Shutting down...",
            "The system will be shut down in " .. SHUTDOWN_DELAY .. " seconds",
            "OK",
            "Cancel",
            "NSCriticalAlertStyle"
          )

          local timer = hs.timer.doAfter(SHUTDOWN_DELAY, function()
            hs.caffeinate.shutdownSystem()
          end)

          if result == "OK" then
            hs.caffeinate.shutdownSystem()
          else
            timer:stop()
          end
        end
      }
    },
    {
      action = "Reload Rakuen Config",
      from = { mods = { "ctrl", "cmd" }, key = "r" },
      to = {
        handler = function()
          hs.alert.show("Rakuen Config Reloaded")

          hs.reload()
        end
      }
    },
    -- TODO: Disable just for 10 seconds, if the eventtap is disabled then no
    -- Rakuen shortcuts will be processed
    -- {
    --   action = "Enable/Disable Rakuen",
    --   from = { mods = { "ctrl", "cmd" }, key = "e" },
    --   to = {
    --     handler = function()
    --       if keyEventListener.isEnabled then
    --         keyEventListener.disable()

    --         hs.alert("Rakuen Disabled")

    --         logger.info("Rakuen Disabled", "General System")
    --       else
    --         keyEventListener.enable()

    --         hs.alert("Rakuen Enabled")

    --         logger.info("Rakuen Enabled", "General System")
    --       end
    --     end
    --   }
    -- }
  }
}

return keybindings