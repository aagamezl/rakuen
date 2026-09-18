local SHUTDOWN_DELAY = 60

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
      -- Kept on Ctrl+Cmd+D (not the spec's Win+D -> Cmd+D) to preserve native
      -- Cmd+D. Uses Mission Control's Cmd+F3, which is more reliable than the
      -- legacy Fn+F11 on modern macOS.
      action = "Show Desktop",
      from = { mods = { "ctrl", "cmd" }, key = "d" },
      to = { mods = { "cmd" }, key = "f3" },
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
      -- Kept on Ctrl+Cmd+M (not the spec's Win+M -> Cmd+M) to preserve native
      -- single-window minimize on Cmd+M.
      action = "Minimize All",
      from = { mods = { "ctrl", "cmd" }, key = "m" },
      to = { mods = { "cmd", "alt" }, key = "m" },
    },
    {
      -- macOS has no PrintScreen key; on external PC keyboards it typically
      -- arrives as F13. Verify the emitted keycode on-device if this does not
      -- trigger (see docs). Full screen -> Cmd+Shift+3, area -> Cmd+Shift+4.
      action = "Screenshot Full Screen",
      from = { mods = {}, key = "f13" },
      to = { mods = { "cmd", "shift" }, key = "3" },
    },
    {
      action = "Screenshot Area",
      from = { mods = { "shift" }, key = "f13" },
      to = { mods = { "cmd", "shift" }, key = "4" },
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

          if result ~= "OK" then
            return
          end

          hs.alert.show("Shutting down in " .. SHUTDOWN_DELAY .. " seconds...", SHUTDOWN_DELAY)

          hs.timer.doAfter(SHUTDOWN_DELAY, function()
            hs.caffeinate.shutdownSystem()
          end)
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
  }
}

return keybindings