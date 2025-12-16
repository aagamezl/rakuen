local modal = false

local keybindings = {
  -- Basic Windows text-editing
  {
    action = "Copy",
    from = { mods = { "ctrl" }, key = "c" },
    to = { mods = { "cmd" }, key = "c" },
    except = {
      "com.apple.Terminal",
      "com.googlecode.iterm2",
      "co.realize.kitty",
      "com.exafunction.windsurf",
      "com.microsoft.VSCode",
    },
  },
  {
    action = "Copy in terminal",
    from = { mods = { "ctrl", "shift" }, key = "c" },
    to = { mods = { "cmd" }, key = "c" },
    only = {
      "com.apple.Terminal",
      "com.googlecode.iterm2",
      "com.github.wez.wezterm",
      "org.alacritty",
      "net.kovidgoyal.kitty",
    },
  },
  {
    action = "Paste",
    from = { mods = { "ctrl" }, key = "v" },
    to = { mods = { "cmd" }, key = "v" },
  },
  {
    action = "Cut",
    from = { mods = { "ctrl" }, key = "x" },
    to = { mods = { "cmd" }, key = "x" },
  },
  {
    action = "Undo",
    from = { mods = { "ctrl" }, key = "z" },
    to = { mods = { "cmd" }, key = "z" },
  },
  {
    action = "Redo",
    from = { mods = { "ctrl" }, key = "y" },
    to = { mods = { "cmd", "shift" }, key = "z" },
  },
  {
    action = "Select All",
    from = { mods = { "ctrl" }, key = "a" },
    to = { mods = { "cmd" }, key = "a" },
  },
  {
    action = "Find",
    from = { mods = { "ctrl" }, key = "f" },
    to = { mods = { "cmd" }, key = "f" },
  },
  {
    action = "Find Next",
    from = { mods = {}, key = "f3" },
    to = { mods = { "cmd" }, key = "g" },
  },
  {
    action = "Find and Replace",
    from = { mods = { "ctrl" }, key = "h" },
    to = { mods = { "cmd", "option" }, key = "f" },
  },
  {
    action = "Bold",
    from = { mods = { "ctrl" }, key = "b" },
    to = { mods = { "cmd" }, key = "b" },
  },
  {
    action = "Italic",
    from = { mods = { "ctrl" }, key = "i" },
    to = { mods = { "cmd" }, key = "i" },
  },
  {
    action = "Underline",
    from = { mods = { "ctrl" }, key = "u" },
    to = { mods = { "cmd" }, key = "u" },
    condition = function()
      if modal then
        print("ctrl + k ctrl+u pressed")

        return false
      end

      return true
    end,
  },
  {
    action = "Save",
    from = { mods = { "ctrl" }, key = "s" },
    to = { mods = { "cmd" }, key = "s" },
  },
  {
    action = "Print",
    from = { mods = { "ctrl" }, key = "p" },
    to = { mods = { "cmd" }, key = "p" },
  },

  {
    -- This modal is used to allow the `ctrl + k ctrl + u` and similar to work
    -- in VS Code based Editors
    -- TODO: Refactor to an independent modal type feature. The modal type
    -- must manage the modal state and the reset timer
    action = "Modal ctrl+k",
    type = "modal",
    from = { mods = { "ctrl" }, key = "k" },
    condition = function()
      hs.timer.doAfter(1, function()
        modal = false

        print("Modal exited")
      end)

      modal = true

      return false
    end,
  },
}

return keybindings
