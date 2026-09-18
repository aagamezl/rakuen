local appGroups = require("utils/app-groups")

local terminals = appGroups.terminals
local terminalsAndEditors = appGroups.terminalsAndEditors

local keybindings = {
  name = "Text Editing",
  rules = {
    {
      action = "Copy",
      from = { mods = { "ctrl" }, key = "c" },
      to = { mods = { "cmd" }, key = "c" },
      except = terminalsAndEditors,
    },
    {
      action = "Copy in terminal",
      from = { mods = { "ctrl", "shift" }, key = "c" },
      to = { mods = { "cmd" }, key = "c" },
      only = terminals,
    },
    {
      action = "Paste",
      from = { mods = { "ctrl" }, key = "v" },
      to = { mods = { "cmd" }, key = "v" },
      except = terminals,
    },
    {
      action = "Paste in Terminal",
      from = { mods = { "ctrl", "shift" }, key = "v" },
      to = { mods = { "cmd" }, key = "v" },
      only = terminals,
    },
    {
      action = "Paste without formatting",
      from = { mods = { "ctrl", "shift" }, key = "v" },
      to = { mods = { "cmd", "alt", "shift" }, key = "v" },
      except = terminals,
    },
    {
      action = "Cut",
      from = { mods = { "ctrl" }, key = "x" },
      to = { mods = { "cmd" }, key = "x" },
      except = terminals,
    },
    {
      action = "Undo",
      from = { mods = { "ctrl" }, key = "z" },
      to = { mods = { "cmd" }, key = "z" },
      except = terminals,
    },
    {
      action = "Redo",
      from = { mods = { "ctrl" }, key = "y" },
      to = { mods = { "cmd", "shift" }, key = "z" },
      except = terminals,
    },
    {
      action = "Select All",
      from = { mods = { "ctrl" }, key = "a" },
      to = { mods = { "cmd" }, key = "a" },
      except = terminals,
    },
    {
      action = "Find",
      from = { mods = { "ctrl" }, key = "f" },
      to = { mods = { "cmd" }, key = "f" },
      except = terminals,
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
      except = terminals,
    },
    {
      action = "Bold",
      from = { mods = { "ctrl" }, key = "b" },
      to = { mods = { "cmd" }, key = "b" },
      except = terminals,
    },
    {
      action = "Italic",
      from = { mods = { "ctrl" }, key = "i" },
      to = { mods = { "cmd" }, key = "i" },
      except = terminals,
    },
    {
      action = "Underline",
      from = { mods = { "ctrl" }, key = "u" },
      to = { mods = { "cmd" }, key = "u" },
      except = terminalsAndEditors,
    },
    {
      action = "Save",
      from = { mods = { "ctrl" }, key = "s" },
      to = { mods = { "cmd" }, key = "s" },
      except = terminalsAndEditors,
    },
    {
      action = "Save As",
      from = { mods = { "ctrl", "shift" }, key = "s" },
      to = { mods = { "cmd", "shift" }, key = "s" },
    },
    {
      action = "Print",
      from = { mods = { "ctrl" }, key = "p" },
      to = { mods = { "cmd" }, key = "p" },
      except = terminals,
    },
    {
      action = "Go to Previous Search Result",
      from = { mods = { "shift" }, key = "f3" },
      to = { mods = { "cmd", "shift" }, key = "g" },
    }
  }
}

return keybindings
